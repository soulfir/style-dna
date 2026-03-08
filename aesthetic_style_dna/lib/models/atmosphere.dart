import 'package:json_annotation/json_annotation.dart';

part 'atmosphere.g.dart';

@JsonSerializable()
class Atmosphere {
  final String mood;

  @JsonKey(name: 'emotional_tone')
  final String emotionalTone;

  final String genre;

  Atmosphere({
    required this.mood,
    required this.emotionalTone,
    required this.genre,
  });

  factory Atmosphere.fromJson(Map<String, dynamic> json) =>
      _$AtmosphereFromJson(json);
  Map<String, dynamic> toJson() => _$AtmosphereToJson(this);
}
