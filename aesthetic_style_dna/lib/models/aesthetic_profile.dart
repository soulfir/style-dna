import 'package:json_annotation/json_annotation.dart';
import 'color_grading.dart';
import 'lighting.dart';
import 'texture_model.dart';
import 'composition.dart';
import 'contrast.dart';
import 'atmosphere.dart';

part 'aesthetic_profile.g.dart';

@JsonSerializable()
class AestheticProfile {
  @JsonKey(name: 'style_tag')
  final String styleTag;

  @JsonKey(name: 'color_grading')
  final ColorGrading colorGrading;

  final Lighting lighting;
  final TextureModel texture;
  final Composition composition;
  final Contrast contrast;
  final Atmosphere atmosphere;

  AestheticProfile({
    required this.styleTag,
    required this.colorGrading,
    required this.lighting,
    required this.texture,
    required this.composition,
    required this.contrast,
    required this.atmosphere,
  });

  factory AestheticProfile.fromJson(Map<String, dynamic> json) =>
      _$AestheticProfileFromJson(json);
  Map<String, dynamic> toJson() => _$AestheticProfileToJson(this);
}
