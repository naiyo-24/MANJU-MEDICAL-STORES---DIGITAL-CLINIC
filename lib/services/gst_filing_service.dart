import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_client.dart';
import '../models/gst_filing.dart';

class GstFilingService {
  static final Dio _dio = ApiClient().dio;

  /// Fetch all GST filings uploaded for the current shop
  static Future<List<GstFiling>> getMyFilings() async {
    try {
      final response = await _dio.get('/api/gst-filing/my-filings');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data;
        return data.map((json) => GstFiling.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ?? e.message ?? 'Failed to load GST filings';
      throw Exception(errorMsg);
    }
  }

  /// Upload a bill file of ANY format along with GST details
  static Future<GstFiling> uploadFiling({
    required Uint8List fileBytes,
    required String fileName,
    required String gstNumber,
    required String turnover,
    required String durationMonths,
    String? filePathOnDisk,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      MultipartFile multipartFile;

      if (!kIsWeb && filePathOnDisk != null && filePathOnDisk.isNotEmpty) {
        multipartFile = await MultipartFile.fromFile(
          filePathOnDisk,
          filename: fileName,
        );
      } else {
        multipartFile = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap({
        'file': multipartFile,
        'gst_number': gstNumber.trim(),
        'turnover': turnover.trim(),
        'duration_months': durationMonths.trim(),
      });

      final response = await _dio.post(
        '/api/gst-filing/upload',
        data: formData,
        onSendProgress: onSendProgress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return GstFiling.fromJson(response.data);
      } else {
        throw Exception('Failed to upload file. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ?? e.message ?? 'Error uploading GST filing file';
      throw Exception(errorMsg);
    }
  }

  /// Delete a GST filing record and its associated physical file
  static Future<bool> deleteFiling(String id) async {
    try {
      final response = await _dio.delete('/api/gst-filing/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ?? e.message ?? 'Failed to delete GST filing';
      throw Exception(errorMsg);
    }
  }

  /// Download file bytes for viewing or saving
  static Future<Uint8List> downloadFilingBytes(String id) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/gst-filing/download/$id',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        return Uint8List.fromList(response.data!);
      }
      throw Exception('Empty file data received');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ?? e.message ?? 'Failed to download file';
      throw Exception(errorMsg);
    }
  }
}
