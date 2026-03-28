import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  final ApiClient _api = ApiClient();
  WebSocketChannel? _channel;

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
      queryParameters: {'page': page},
    );
    final list =
        response.data is List ? response.data : response.data['data'] ?? [];
    return (list as List).map((e) => MessageModel.fromJson(e)).toList();
  }

  Future<WebSocketChannel> connectWebSocket() async {
    final token = await SecureStorage.getAccessToken();
    final uri = Uri.parse(
        '${AppConfig.wsBaseUrl}/chat?token=$token');
    _channel = WebSocketChannel.connect(uri);
    return _channel!;
  }

  void sendMessage(MessageModel message) {
    _channel?.sink.add(jsonEncode(message.toJson()));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
