import 'package:json_annotation/json_annotation.dart';

part 'contrast.g.dart';

@JsonSerializable()
class Contrast {
  @JsonKey(name: 'dynamic_range')
  final String dynamicRange;

  @JsonKey(name: 'shadow_depth')
  final String shadowDepth;

  @JsonKey(name: 'highlight_character')
  final String highlightCharacter;

  Contrast({
    required this.dynamicRange,
    required this.shadowDepth,
    required this.highlightCharacter,
  });

  factory Contrast.fromJson(Map<String, dynamic> json) =>
      _$ContrastFromJson(json);
  Map<String, dynamic> toJson() => _$ContrastToJson(this);
}
