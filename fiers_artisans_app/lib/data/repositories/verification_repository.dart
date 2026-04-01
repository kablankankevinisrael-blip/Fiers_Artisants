import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class VerificationRepository {
  final ApiClient _api = ApiClient();

  /// Uploads a file to the verifications bucket.
  /// Returns the URL of the uploaded file.
  Future<String> uploadDocument(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _api.dio.post(
      ApiEndpoints.upload,
      data: formData,
      queryParameters: {'bucket': 'verifications'},
    );
    final data = response.data;
    return data['url'] as String;
  }

  /// Submits a verification document to the backend.
  Future<Map<String, dynamic>> submitDocument({
    required String documentType,
    required String fileUrl,
  }) async {
    final response = await _api.post(
      ApiEndpoints.verificationSubmit,
      data: {
        'document_type': documentType,
        'file_url': fileUrl,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Fetches the current verification status and documents.
  Future<Map<String, dynamic>> getVerificationStatus() async {
    final response = await _api.get(ApiEndpoints.verificationStatus);
    return response.data as Map<String, dynamic>;
  }
}
