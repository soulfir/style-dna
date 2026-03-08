// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'texture_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextureModel _$TextureModelFromJson(Map<String, dynamic> json) => TextureModel(
  grain: json['grain'] as String,
  surfaceQuality: json['surface_quality'] as String,
  sharpness: json['sharpness'] as String,
);

Map<String, dynamic> _$TextureModelToJson(TextureModel instance) =>
    <String, dynamic>{
      'grain': instance.grain,
      'surface_quality': instance.surfaceQuality,
      'sharpness': instance.sharpness,
    };
