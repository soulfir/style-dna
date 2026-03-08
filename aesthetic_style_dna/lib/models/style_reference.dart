import 'package:json_annotation/json_annotation.dart';
import 'aesthetic_profile.dart';

part 'style_reference.g.dart';

@JsonSerializable()
class StyleReference {
  final String id;

  @JsonKey(name: 'style_tag')
  final String styleTag;

  final AestheticProfile profile;

  @JsonKey(name: 'source_image_path')
  final String? sourceImagePath;

  @JsonKey(name: 'created_at')
  final String createdAt;

  StyleReference({
    required this.id,
    required this.styleTag,
    required this.profile,
    this.sourceImagePath,
    required this.createdAt,
  });

  factory StyleReference.fromJson(Map<String, dynamic> json) =>
      _$StyleReferenceFromJson(json);
  Map<String, dynamic> toJson() => _$StyleReferenceToJson(this);
}
