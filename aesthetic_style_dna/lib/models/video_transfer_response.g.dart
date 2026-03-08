// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_transfer_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoInfo _$VideoInfoFromJson(Map<String, dynamic> json) => VideoInfo(
  duration: (json['duration'] as num).toDouble(),
  fps: (json['fps'] as num).toDouble(),
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  hasAudio: json['has_audio'] as bool,
  totalFrames: (json['total_frames'] as num).toInt(),
);

Map<String, dynamic> _$VideoInfoToJson(VideoInfo instance) => <String, dynamic>{
  'duration': instance.duration,
  'fps': instance.fps,
  'width': instance.width,
  'height': instance.height,
  'has_audio': instance.hasAudio,
  'total_frames': instance.totalFrames,
};

VideoTransferResponse _$VideoTransferResponseFromJson(
  Map<String, dynamic> json,
) => VideoTransferResponse(
  jobId: json['job_id'] as String,
  message: json['message'] as String,
  estimatedDuration: (json['estimated_duration'] as num).toDouble(),
  videoInfo: VideoInfo.fromJson(json['video_info'] as Map<String, dynamic>),
);

Map<String, dynamic> _$VideoTransferResponseToJson(
  VideoTransferResponse instance,
) => <String, dynamic>{
  'job_id': instance.jobId,
  'message': instance.message,
  'estimated_duration': instance.estimatedDuration,
  'video_info': instance.videoInfo,
};
