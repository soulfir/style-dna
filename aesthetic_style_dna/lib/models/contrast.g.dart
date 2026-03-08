// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contrast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Contrast _$ContrastFromJson(Map<String, dynamic> json) => Contrast(
  dynamicRange: json['dynamic_range'] as String,
  shadowDepth: json['shadow_depth'] as String,
  highlightCharacter: json['highlight_character'] as String,
);

Map<String, dynamic> _$ContrastToJson(Contrast instance) => <String, dynamic>{
  'dynamic_range': instance.dynamicRange,
  'shadow_depth': instance.shadowDepth,
  'highlight_character': instance.highlightCharacter,
};
