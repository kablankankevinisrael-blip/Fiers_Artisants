import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  final ApiClient _api = ApiClient();

  Future<List<ConversationModel>> getConversations() async {
    final response = await _api.get(ApiEndpoints.conversations);
    final list =
        response.data is List ? response.data : response.data['data'] ?? [];
    return (list as List).map((e) => ConversationModel.fromJson(e)).toList();
  }

  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int page = 1,
  }) async {
    final response = await _api.get(
      ApiEndpoints.messages(conversationId),
      queryParameters: {'page': page, 'limit': 50},
    );
    final list =
        response.data is List ? response.data : response.data['data'] ?? [];
    return (list as List).map((e) => MessageModel.fromJson(e)).toList();
  }

  /// Send a message via REST (reliable path).
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String? type,
    String? mediaUrl,
  }) async {
    final body = <String, dynamic>{'content': content};
    if (type != null) body['type'] = type;
    if (mediaUrl != null) body['mediaUrl'] = mediaUrl;

    final response = await _api.post(
      ApiEndpoints.messages(conversationId),
      data: body,
    );
    return MessageModel.fromJson(response.data);
  }

  /// Create a new conversation with a participant.
  Future<ConversationModel> createConversation(String participantId) async {
    final response = await _api.post(
      ApiEndpoints.conversations,
      data: {'participantId': participantId},
    );
    return ConversationModel.fromJson(response.data);
  }

  /// Mark all messages in a conversation as read.
  Future<void> markAsRead(String conversationId) async {
    await _api.put(ApiEndpoints.conversationRead(conversationId));
  }
}
