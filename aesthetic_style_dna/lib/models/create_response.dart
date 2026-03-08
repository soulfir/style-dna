import 'package:json_annotation/json_annotation.dart';

part 'create_response.g.dart';

@JsonSerializable()
class CreateResponse {
  @JsonKey(name: 'image_url')
  final String imageUrl;

  @JsonKey(name: 'prompt_used')
  final String promptUsed;

  final String message;

  CreateResponse({
    required this.imageUrl,
    required this.promptUsed,
    required this.message,
  });

  factory CreateResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CreateResponseToJson(this);
}
