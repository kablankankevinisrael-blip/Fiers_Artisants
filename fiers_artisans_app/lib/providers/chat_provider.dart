import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/models/conversation_model.dart';
import '../data/models/message_model.dart';
import '../data/repositories/chat_repository.dart';
import '../core/storage/secure_storage.dart';
import '../services/chat_realtime_service.dart';

class ChatState {
  final List<ConversationModel> conversations;
  final List<MessageModel> messages;
  final bool isLoading;
  final String? activeConversationId;
  final String? errorMessage;
  final bool authRequired;

  const ChatState({
    this.conversations = const [],
    this.messages = const [],
    this.isLoading = false,
    this.activeConversationId,
    this.errorMessage,
    this.authRequired = false,
  });

  ChatState copyWith({
    List<ConversationModel>? conversations,
    List<MessageModel>? messages,
    bool? isLoading,
    String? activeConversationId,
    String? errorMessage,
    bool? authRequired,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      errorMessage: errorMessage,
      authRequired: authRequired ?? this.authRequired,
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repo = ChatRepository();
  final ChatRealtimeService _realtime = ChatRealtimeService();

  StreamSubscription<Map<String, dynamic>>? _newMessageSub;
  StreamSubscription<Map<String, dynamic>>? _messagesReadSub;
  String? _currentUserId;

  ChatNotifier() : super(const ChatState()) {
    unawaited(_initializeRealtime());
  }

  @override
  void dispose() {
    _newMessageSub?.cancel();
    _messagesReadSub?.cancel();
    super.dispose();
  }

  Future<void> _initializeRealtime() async {
    _currentUserId = await SecureStorage.getUserId();
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return;
    }

    await _realtime.connect(userId: _currentUserId!);

    await _newMessageSub?.cancel();
    await _messagesReadSub?.cancel();

    _newMessageSub = _realtime.newMessages.listen(_onSocketNewMessage);
    _messagesReadSub = _realtime.messagesRead.listen(_onSocketMessagesRead);
  }

  Future<void> _ensureRealtimeConnected() async {
    if (_currentUserId == null ||
        _currentUserId!.isEmpty ||
        !_realtime.isConnected) {
      await _initializeRealtime();
    }
  }

  Future<void> loadConversations() async {
    await _ensureRealtimeConnected();
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final convos = await _repo.getConversations();
      for (final convo in convos) {
        _realtime.joinConversation(convo.id);
      }
      state = state.copyWith(
        conversations: convos,
        isLoading: false,
        authRequired: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        authRequired: _isUnauthorizedError(e),
        errorMessage: 'Impossible de charger les conversations.',
      );
    }
  }

  Future<void> loadMessages(String conversationId) async {
    await _ensureRealtimeConnected();
    state = state.copyWith(
      isLoading: true,
      activeConversationId: conversationId,
      errorMessage: null,
    );
    try {
      final msgs = await _repo.getMessages(conversationId);
      _realtime.joinConversation(conversationId);
      state = state.copyWith(
        messages: msgs,
        isLoading: false,
        authRequired: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        authRequired: _isUnauthorizedError(e),
        errorMessage: 'Impossible de charger les messages.',
      );
    }
  }

  void addMessage(MessageModel message) {
    if (state.messages.any((m) => m.id == message.id)) {
      return;
    }
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void removeMessage(String messageId) {
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != messageId).toList(),
    );
  }

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    required String tempId,
  }) async {
    await _ensureRealtimeConnected();
    try {
      final sent = await _repo.sendMessage(
        conversationId: conversationId,
        content: content,
      );

      // Replace the optimistic temp message with the real server response.
      final updated = state.messages.map((m) {
        if (m.id == tempId) return sent;
        return m;
      }).toList();
      state = state.copyWith(messages: updated, authRequired: false);
      _applyConversationPreview(sent);
      return sent;
    } catch (e) {
      state = state.copyWith(
        authRequired: _isUnauthorizedError(e),
        errorMessage: 'Envoi du message impossible.',
      );
      rethrow;
    }
  }

  Future<ConversationModel> createConversation(String participantId) async {
    await _ensureRealtimeConnected();
    try {
      final convo = await _repo.createConversation(participantId);
      _realtime.joinConversation(convo.id);
      final merged = _upsertConversation(state.conversations, convo);
      state = state.copyWith(conversations: merged, authRequired: false);
      return convo;
    } catch (e) {
      state = state.copyWith(
        authRequired: _isUnauthorizedError(e),
        errorMessage: 'Impossible de demarrer la conversation.',
      );
      rethrow;
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _repo.markAsRead(conversationId);
      final updatedConversations = state.conversations.map((c) {
        if (c.id != conversationId) return c;
        return ConversationModel(
          id: c.id,
          participantId: c.participantId,
          participantName: c.participantName,
          participantAvatarUrl: c.participantAvatarUrl,
          lastMessage: c.lastMessage,
          lastMessageAt: c.lastMessageAt,
          unreadCount: 0,
        );
      }).toList();

      final updatedMessages = state.messages.map((m) {
        if (m.conversationId != conversationId) return m;
        if (m.senderId == _currentUserId) return m;
        return MessageModel(
          id: m.id,
          conversationId: m.conversationId,
          senderId: m.senderId,
          content: m.content,
          type: m.type,
          createdAt: m.createdAt,
          isRead: true,
        );
      }).toList();

      state = state.copyWith(
        conversations: updatedConversations,
        messages: updatedMessages,
      );
    } catch (_) {}
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  bool _isUnauthorizedError(Object error) {
    if (error is DioException) {
      return error.response?.statusCode == 401;
    }
    return error.toString().contains('401');
  }

  List<ConversationModel> _upsertConversation(
    List<ConversationModel> current,
    ConversationModel incoming,
  ) {
    final idx = current.indexWhere((c) => c.id == incoming.id);
    if (idx == -1) {
      return [incoming, ...current];
    }
    final updated = [...current];
    updated[idx] = incoming;
    return updated;
  }

  void _onSocketNewMessage(Map<String, dynamic> payload) {
    final message = MessageModel.fromJson(payload);

    if (message.id.isEmpty || message.conversationId.isEmpty) {
      return;
    }

    final isActiveConversation =
        state.activeConversationId == message.conversationId;
    final messageExists = state.messages.any((m) => m.id == message.id);

    if (isActiveConversation && !messageExists) {
      state = state.copyWith(messages: [...state.messages, message]);
    }

    _applyConversationPreview(message);

    if (isActiveConversation && message.senderId != _currentUserId) {
      unawaited(markAsRead(message.conversationId));
    }

    if (state.conversations.every((c) => c.id != message.conversationId)) {
      unawaited(loadConversations());
    }
  }

  void _onSocketMessagesRead(Map<String, dynamic> payload) {
    final conversationId = payload['conversationId']?.toString();
    final readerUserId = payload['userId']?.toString();
    if (conversationId == null || conversationId.isEmpty) {
      return;
    }

    if (readerUserId == _currentUserId) {
      final updatedConversations = state.conversations.map((c) {
        if (c.id != conversationId) return c;
        return ConversationModel(
          id: c.id,
          participantId: c.participantId,
          participantName: c.participantName,
          participantAvatarUrl: c.participantAvatarUrl,
          lastMessage: c.lastMessage,
          lastMessageAt: c.lastMessageAt,
          unreadCount: 0,
        );
      }).toList();
      state = state.copyWith(conversations: updatedConversations);
    }
  }

  void _applyConversationPreview(MessageModel message) {
    final updated = state.conversations.map((c) {
      if (c.id != message.conversationId) return c;

      final shouldIncrementUnread =
          message.senderId != _currentUserId &&
          state.activeConversationId != message.conversationId;

      return ConversationModel(
        id: c.id,
        participantId: c.participantId,
        participantName: c.participantName,
        participantAvatarUrl: c.participantAvatarUrl,
        lastMessage: message.content,
        lastMessageAt: message.createdAt,
        unreadCount: shouldIncrementUnread ? c.unreadCount + 1 : c.unreadCount,
      );
    }).toList();

    state = state.copyWith(conversations: updated);
  }
}
