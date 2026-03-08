// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'style_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StyleListResponse _$StyleListResponseFromJson(Map<String, dynamic> json) =>
    StyleListResponse(
      styles: (json['styles'] as List<dynamic>)
          .map((e) => StyleReference.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$StyleListResponseToJson(StyleListResponse instance) =>
    <String, dynamic>{'styles': instance.styles, 'count': instance.count};
