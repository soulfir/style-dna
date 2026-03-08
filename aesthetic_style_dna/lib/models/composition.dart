import 'package:json_annotation/json_annotation.dart';

part 'composition.g.dart';

@JsonSerializable()
class Composition {
  final String technique;

  @JsonKey(name: 'depth_layers')
  final String depthLayers;

  final String framing;

  Composition({
    required this.technique,
    required this.depthLayers,
    required this.framing,
  });

  factory Composition.fromJson(Map<String, dynamic> json) =>
      _$CompositionFromJson(json);
  Map<String, dynamic> toJson() => _$CompositionToJson(this);
}
