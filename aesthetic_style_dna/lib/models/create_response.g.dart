// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateResponse _$CreateResponseFromJson(Map<String, dynamic> json) =>
    CreateResponse(
      imageUrl: json['image_url'] as String,
      promptUsed: json['prompt_used'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$CreateResponseToJson(CreateResponse instance) =>
    <String, dynamic>{
      'image_url': instance.imageUrl,
      'prompt_used': instance.promptUsed,
      'message': instance.message,
    };
