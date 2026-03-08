// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_job_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoJobStatus _$VideoJobStatusFromJson(Map<String, dynamic> json) =>
    VideoJobStatus(
      jobId: json['job_id'] as String,
      status: json['status'] as String,
      progress: (json['progress'] as num).toDouble(),
      totalFrames: (json['total_frames'] as num).toInt(),
      processedFrames: (json['processed_frames'] as num).toInt(),
      styleId: json['style_id'] as String,
      resultUrl: json['result_url'] as String?,
      error: json['error'] as String?,
      estimatedTimeRemaining: (json['estimated_time_remaining'] as num?)
          ?.toDouble(),
    );

Map<String, dynamic> _$VideoJobStatusToJson(VideoJobStatus instance) =>
    <String, dynamic>{
      'job_id': instance.jobId,
      'status': instance.status,
      'progress': instance.progress,
      'total_frames': instance.totalFrames,
      'processed_frames': instance.processedFrames,
      'style_id': instance.styleId,
      'result_url': instance.resultUrl,
      'error': instance.error,
      'estimated_time_remaining': instance.estimatedTimeRemaining,
    };
