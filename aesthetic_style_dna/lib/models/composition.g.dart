// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'composition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Composition _$CompositionFromJson(Map<String, dynamic> json) => Composition(
  technique: json['technique'] as String,
  depthLayers: json['depth_layers'] as String,
  framing: json['framing'] as String,
);

Map<String, dynamic> _$CompositionToJson(Composition instance) =>
    <String, dynamic>{
      'technique': instance.technique,
      'depth_layers': instance.depthLayers,
      'framing': instance.framing,
    };
