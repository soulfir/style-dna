import 'package:json_annotation/json_annotation.dart';

part 'texture_model.g.dart';

@JsonSerializable()
class TextureModel {
  final String grain;

  @JsonKey(name: 'surface_quality')
  final String surfaceQuality;

  final String sharpness;

  TextureModel({
    required this.grain,
    required this.surfaceQuality,
    required this.sharpness,
  });

  factory TextureModel.fromJson(Map<String, dynamic> json) =>
      _$TextureModelFromJson(json);
  Map<String, dynamic> toJson() => _$TextureModelToJson(this);
}
