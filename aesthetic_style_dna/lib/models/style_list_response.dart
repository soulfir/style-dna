import 'package:json_annotation/json_annotation.dart';
import 'style_reference.dart';

part 'style_list_response.g.dart';

@JsonSerializable()
class StyleListResponse {
  final List<StyleReference> styles;
  final int count;

  StyleListResponse({required this.styles, required this.count});

  factory StyleListResponse.fromJson(Map<String, dynamic> json) =>
      _$StyleListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StyleListResponseToJson(this);
}
