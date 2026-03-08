import '../config/api_config.dart';

String resolveSourceImageUrl(String? serverPath) {
  return ApiConfig.resolveSourceImageUrl(serverPath);
}

String resolveOutputImageUrl(String imageUrl) {
  if (imageUrl.startsWith('http')) return imageUrl;
  return ApiConfig.outputUrl(imageUrl);
}

double levelToValue(String level, List<String> levels) {
  final index = levels.indexOf(level.toLowerCase());
  if (index < 0) return 0.5;
  return (index + 1) / levels.length;
}
