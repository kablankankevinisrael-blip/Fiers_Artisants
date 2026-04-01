import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/conversation_model.dart';
import '../data/models/message_model.dart';
import '../data/repositories/chat_repository.dart';

class ChatState {
  final List<ConversationModel> conversations;
  final List<MessageModel> messages;
  final bool isLoading;
  final String? activeConversationId;

  const ChatState({
    this.conversations = const [],
    this.messages = const [],
    this.isLoading = false,
    this.activeConversationId,
  });

  ChatState copyWith({
    List<ConversationModel>? conversations,
    List<MessageModel>? messages,
    bool? isLoading,
    String? activeConversationId,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      activeConversationId:
          activeConversationId ?? this.activeConversationId,
    );
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repo = ChatRepository();

  ChatNotifier() : super(const ChatState());

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true);
    try {
      final convos = await _repo.getConversations();
      state = state.copyWith(conversations: convos, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMessages(String conversationId) async {
    state = state.copyWith(
      isLoading: true,
      activeConversationId: conversationId,
    );
    try {
      final msgs = await _repo.getMessages(conversationId);
      state = state.copyWith(messages: msgs, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void addMessage(MessageModel message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    // Don't add to state here — the caller already added an optimistic message
    final sent = await _repo.sendMessage(
      conversationId: conversationId,
      content: content,
    );
    // Replace the optimistic temp message with the real server response
    final updated = state.messages.map((m) {
      if (m.id.startsWith('temp_') && m.content == content) return sent;
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
    return sent;
  }

  Future<ConversationModel> createConversation(String participantId) async {
    final convo = await _repo.createConversation(participantId);
    state = state.copyWith(
      conversations: [...state.conversations, convo],
    );
    return convo;
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _repo.markAsRead(conversationId);
    } catch (_) {}
  }

  void disconnect() {
    _repo.disconnect();
  }
}
