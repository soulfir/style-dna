import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 120),
      headers: {'Accept': 'application/json'},
    ));
  }

  Future<Response> get(String path) => dio.get(path);

  Future<Response> post(String path, {dynamic data, Options? options}) =>
      dio.post(path, data: data, options: options);

  Future<Response> delete(String path) => dio.delete(path);
}
