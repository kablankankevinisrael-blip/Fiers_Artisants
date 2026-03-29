import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  final ApiClient _api = ApiClient();

  Future<SubscriptionModel?> getStatus() async {
    try {
      final response = await _api.get(ApiEndpoints.subscriptionStatus);
      return SubscriptionModel.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> initiatePayment() async {
    final response = await _api.post(ApiEndpoints.subscriptionInitiate);
    return response.data;
  }
}
