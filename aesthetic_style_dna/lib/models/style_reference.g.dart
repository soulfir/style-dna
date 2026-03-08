// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'style_reference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StyleReference _$StyleReferenceFromJson(Map<String, dynamic> json) =>
    StyleReference(
      id: json['id'] as String,
      styleTag: json['style_tag'] as String,
      profile: AestheticProfile.fromJson(
        json['profile'] as Map<String, dynamic>,
      ),
      sourceImagePath: json['source_image_path'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$StyleReferenceToJson(StyleReference instance) =>
    <String, dynamic>{
      'id': instance.id,
      'style_tag': instance.styleTag,
      'profile': instance.profile,
      'source_image_path': instance.sourceImagePath,
      'created_at': instance.createdAt,
    };
