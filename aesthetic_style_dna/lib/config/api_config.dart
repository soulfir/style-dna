class ApiConfig {
  static const String baseUrl = 'http://localhost:8080';
  static const String analyzeEndpoint = '/analyze';
  static const String createEndpoint = '/create';
  static const String transferEndpoint = '/transfer';
  static const String videoTransferEndpoint = '/transfer/video';
  static const String videoTransferFastEndpoint = '/transfer/video/fast';
  static String videoJobEndpoint(String jobId) => '/transfer/video/$jobId';
  static const String videoJobsEndpoint = '/transfer/video/jobs';
  static const String stylesEndpoint = '/styles';

  static String styleEndpoint(String id) => '/styles/$id';
  static String uploadsUrl(String filename) => '$baseUrl/uploads/$filename';
  static String outputUrl(String path) => '$baseUrl$path';

  static String resolveSourceImageUrl(String? serverPath) {
    if (serverPath == null || serverPath.isEmpty) return '';
    final filename = serverPath.split('/').last;
    return uploadsUrl(filename);
  }
}
