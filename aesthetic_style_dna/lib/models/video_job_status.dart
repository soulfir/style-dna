import 'package:json_annotation/json_annotation.dart';

part 'video_job_status.g.dart';

@JsonSerializable()
class VideoJobStatus {
  @JsonKey(name: 'job_id')
  final String jobId;

  final String status;

  final double progress;

  @JsonKey(name: 'total_frames')
  final int totalFrames;

  @JsonKey(name: 'processed_frames')
  final int processedFrames;

  @JsonKey(name: 'style_id')
  final String styleId;

  @JsonKey(name: 'result_url')
  final String? resultUrl;

  final String? error;

  @JsonKey(name: 'estimated_time_remaining')
  final double? estimatedTimeRemaining;

  VideoJobStatus({
    required this.jobId,
    required this.status,
    required this.progress,
    required this.totalFrames,
    required this.processedFrames,
    required this.styleId,
    this.resultUrl,
    this.error,
    this.estimatedTimeRemaining,
  });

  factory VideoJobStatus.fromJson(Map<String, dynamic> json) =>
      _$VideoJobStatusFromJson(json);
  Map<String, dynamic> toJson() => _$VideoJobStatusToJson(this);
}
