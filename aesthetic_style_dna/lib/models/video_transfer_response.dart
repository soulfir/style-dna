import 'package:json_annotation/json_annotation.dart';

part 'video_transfer_response.g.dart';

@JsonSerializable()
class VideoInfo {
  final double duration;
  final double fps;
  final int width;
  final int height;

  @JsonKey(name: 'has_audio')
  final bool hasAudio;

  @JsonKey(name: 'total_frames')
  final int totalFrames;

  VideoInfo({
    required this.duration,
    required this.fps,
    required this.width,
    required this.height,
    required this.hasAudio,
    required this.totalFrames,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoFromJson(json);
  Map<String, dynamic> toJson() => _$VideoInfoToJson(this);
}

@JsonSerializable()
class VideoTransferResponse {
  @JsonKey(name: 'job_id')
  final String jobId;

  final String message;

  @JsonKey(name: 'estimated_duration')
  final double estimatedDuration;

  @JsonKey(name: 'video_info')
  final VideoInfo videoInfo;

  VideoTransferResponse({
    required this.jobId,
    required this.message,
    required this.estimatedDuration,
    required this.videoInfo,
  });

  factory VideoTransferResponse.fromJson(Map<String, dynamic> json) =>
      _$VideoTransferResponseFromJson(json);
  Map<String, dynamic> toJson() => _$VideoTransferResponseToJson(this);
}
