import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/analyze_response.dart';
import '../models/create_response.dart';
import '../models/video_transfer_response.dart';
import '../models/video_job_status.dart';
import '../models/style_reference.dart';
import '../models/style_list_response.dart';
import 'api_client.dart';

class StyleService {
  final ApiClient _client;

  StyleService(this._client);

  Future<AnalyzeResponse> analyzeImage(File file, {String? customTag}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path,
            filename: file.path.split('/').last),
        if (customTag != null && customTag.isNotEmpty) 'custom_tag': customTag,
      });
      final response =
          await _client.post(ApiConfig.analyzeEndpoint, data: formData);
      return AnalyzeResponse.fromJson(response.data);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Analysis failed: $detail');
    }
  }

  Future<CreateResponse> createImage({
    required List<String> styleIds,
    String? prompt,
    int? seed,
    int width = 1024,
    int height = 1024,
    File? referenceImage,
  }) async {
    try {
      final formData = FormData.fromMap({
        'style_ids': jsonEncode(styleIds),
        if (prompt != null && prompt.isNotEmpty) 'prompt': prompt,
        if (seed != null) 'seed': seed,
        'width': width,
        'height': height,
        if (referenceImage != null)
          'reference_image': await MultipartFile.fromFile(referenceImage.path,
              filename: referenceImage.path.split('/').last),
      });
      final response =
          await _client.post(ApiConfig.createEndpoint, data: formData);
      return CreateResponse.fromJson(response.data);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Generation failed: $detail');
    }
  }

  Future<CreateResponse> transferImage({
    required File image,
    required String styleId,
    int? seed,
    int width = 1024,
    int height = 1024,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(image.path,
            filename: image.path.split('/').last),
        'style_id': styleId,
        if (seed != null) 'seed': seed,
        'width': width,
        'height': height,
      });
      final response =
          await _client.post(ApiConfig.transferEndpoint, data: formData);
      return CreateResponse.fromJson(response.data);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Style transfer failed: $detail');
    }
  }

  Future<List<StyleReference>> getStyles() async {
    final response = await _client.get(ApiConfig.stylesEndpoint);
    final listResponse = StyleListResponse.fromJson(response.data);
    return listResponse.styles;
  }

  Future<StyleReference> getStyle(String id) async {
    final response = await _client.get(ApiConfig.styleEndpoint(id));
    return StyleReference.fromJson(response.data);
  }

  Future<void> deleteStyle(String id) async {
    await _client.delete(ApiConfig.styleEndpoint(id));
  }

  Future<VideoTransferResponse> submitVideoTransfer({
    required File video,
    required String styleId,
    int sampleRate = 4,
    int maxFrames = 120,
    int? seed,
    int maxWorkers = 4,
    bool temporalSmoothing = true,
  }) async {
    try {
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(video.path,
            filename: video.path.split('/').last),
        'style_id': styleId,
        'sample_rate': sampleRate,
        'max_frames': maxFrames,
        if (seed != null) 'seed': seed,
        'max_workers': maxWorkers,
        'temporal_smoothing': temporalSmoothing,
      });
      final response = await _client.post(
        ApiConfig.videoTransferEndpoint,
        data: formData,
        options: Options(receiveTimeout: const Duration(seconds: 300)),
      );
      return VideoTransferResponse.fromJson(response.data);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Video transfer failed: $detail');
    }
  }

  Future<VideoTransferResponse> submitFastVideoTransfer({
    required File video,
    required String styleId,
    int numKeyframes = 6,
    int? seed,
    int maxWorkers = 4,
  }) async {
    try {
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(video.path,
            filename: video.path.split('/').last),
        'style_id': styleId,
        'num_keyframes': numKeyframes,
        if (seed != null) 'seed': seed,
        'max_workers': maxWorkers,
      });
      final response = await _client.post(
        ApiConfig.videoTransferFastEndpoint,
        data: formData,
        options: Options(receiveTimeout: const Duration(seconds: 300)),
      );
      return VideoTransferResponse.fromJson(response.data);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Fast video transfer failed: $detail');
    }
  }

  Future<VideoJobStatus> getVideoJobStatus(String jobId) async {
    try {
      final response =
          await _client.get(ApiConfig.videoJobEndpoint(jobId));
      return VideoJobStatus.fromJson(response.data);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Failed to get job status: $detail');
    }
  }

  Future<List<VideoJobStatus>> getVideoJobs() async {
    try {
      final response = await _client.get(ApiConfig.videoJobsEndpoint);
      return (response.data as List)
          .map((j) => VideoJobStatus.fromJson(j))
          .toList();
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Failed to get video jobs: $detail');
    }
  }
}
