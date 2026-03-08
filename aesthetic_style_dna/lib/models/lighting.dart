import 'package:json_annotation/json_annotation.dart';

part 'lighting.g.dart';

@JsonSerializable()
class Lighting {
  final String direction;
  final String quality;

  @JsonKey(name: 'contrast_ratio')
  final String contrastRatio;

  final String mood;

  Lighting({
    required this.direction,
    required this.quality,
    required this.contrastRatio,
    required this.mood,
  });

  factory Lighting.fromJson(Map<String, dynamic> json) =>
      _$LightingFromJson(json);
  Map<String, dynamic> toJson() => _$LightingToJson(this);
}
