import 'package:json_annotation/json_annotation.dart';
import 'style_reference.dart';

part 'analyze_response.g.dart';

@JsonSerializable()
class AnalyzeResponse {
  final StyleReference style;
  final String message;

  AnalyzeResponse({required this.style, required this.message});

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) =>
      _$AnalyzeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AnalyzeResponseToJson(this);
}
