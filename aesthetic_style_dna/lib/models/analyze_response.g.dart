// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analyze_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyzeResponse _$AnalyzeResponseFromJson(Map<String, dynamic> json) =>
    AnalyzeResponse(
      style: StyleReference.fromJson(json['style'] as Map<String, dynamic>),
      message: json['message'] as String,
    );

Map<String, dynamic> _$AnalyzeResponseToJson(AnalyzeResponse instance) =>
    <String, dynamic>{'style': instance.style, 'message': instance.message};
