// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'color_grading.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ColorGrading _$ColorGradingFromJson(Map<String, dynamic> json) => ColorGrading(
  dominantColors: (json['dominant_colors'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  paletteType: json['palette_type'] as String,
  colorTemperature: json['color_temperature'] as String,
  saturation: json['saturation'] as String,
);

Map<String, dynamic> _$ColorGradingToJson(ColorGrading instance) =>
    <String, dynamic>{
      'dominant_colors': instance.dominantColors,
      'palette_type': instance.paletteType,
      'color_temperature': instance.colorTemperature,
      'saturation': instance.saturation,
    };
