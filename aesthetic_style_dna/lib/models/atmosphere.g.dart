// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'atmosphere.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Atmosphere _$AtmosphereFromJson(Map<String, dynamic> json) => Atmosphere(
  mood: json['mood'] as String,
  emotionalTone: json['emotional_tone'] as String,
  genre: json['genre'] as String,
);

Map<String, dynamic> _$AtmosphereToJson(Atmosphere instance) =>
    <String, dynamic>{
      'mood': instance.mood,
      'emotional_tone': instance.emotionalTone,
      'genre': instance.genre,
    };
