import 'package:json_annotation/json_annotation.dart';

part 'color_grading.g.dart';

@JsonSerializable()
class ColorGrading {
  @JsonKey(name: 'dominant_colors')
  final List<String> dominantColors;

  @JsonKey(name: 'palette_type')
  final String paletteType;

  @JsonKey(name: 'color_temperature')
  final String colorTemperature;

  final String saturation;

  ColorGrading({
    required this.dominantColors,
    required this.paletteType,
    required this.colorTemperature,
    required this.saturation,
  });

  factory ColorGrading.fromJson(Map<String, dynamic> json) =>
      _$ColorGradingFromJson(json);
  Map<String, dynamic> toJson() => _$ColorGradingToJson(this);
}
