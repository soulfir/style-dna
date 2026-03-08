// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lighting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lighting _$LightingFromJson(Map<String, dynamic> json) => Lighting(
  direction: json['direction'] as String,
  quality: json['quality'] as String,
  contrastRatio: json['contrast_ratio'] as String,
  mood: json['mood'] as String,
);

Map<String, dynamic> _$LightingToJson(Lighting instance) => <String, dynamic>{
  'direction': instance.direction,
  'quality': instance.quality,
  'contrast_ratio': instance.contrastRatio,
  'mood': instance.mood,
};
