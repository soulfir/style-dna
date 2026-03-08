// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aesthetic_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AestheticProfile _$AestheticProfileFromJson(Map<String, dynamic> json) =>
    AestheticProfile(
      styleTag: json['style_tag'] as String,
      colorGrading: ColorGrading.fromJson(
        json['color_grading'] as Map<String, dynamic>,
      ),
      lighting: Lighting.fromJson(json['lighting'] as Map<String, dynamic>),
      texture: TextureModel.fromJson(json['texture'] as Map<String, dynamic>),
      composition: Composition.fromJson(
        json['composition'] as Map<String, dynamic>,
      ),
      contrast: Contrast.fromJson(json['contrast'] as Map<String, dynamic>),
      atmosphere: Atmosphere.fromJson(
        json['atmosphere'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$AestheticProfileToJson(AestheticProfile instance) =>
    <String, dynamic>{
      'style_tag': instance.styleTag,
      'color_grading': instance.colorGrading,
      'lighting': instance.lighting,
      'texture': instance.texture,
      'composition': instance.composition,
      'contrast': instance.contrast,
      'atmosphere': instance.atmosphere,
    };
