import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_transfer_response.dart';
import '../models/video_job_status.dart';
import 'style_library_provider.dart';

enum VideoTransferPhase { idle, uploading, processing, completed, failed }

class VideoTransferState {
  final VideoTransferPhase phase;
  final VideoTransferResponse? jobResponse;
  final VideoJobStatus? latestStatus;
  final String? error;

  const VideoTransferState({
    this.phase = VideoTransferPhase.idle,
    this.jobResponse,
    this.latestStatus,
    this.error,
  });

  VideoTransferState copyWith({
    VideoTransferPhase? phase,
    VideoTransferResponse? jobResponse,
    VideoJobStatus? latestStatus,
    String? error,
  }) {
    return VideoTransferState(
      phase: phase ?? this.phase,
      jobResponse: jobResponse ?? this.jobResponse,
      latestStatus: latestStatus ?? this.latestStatus,
      error: error ?? this.error,
    );
  }
}

final videoTransferProvider =
    NotifierProvider<VideoTransferNotifier, VideoTransferState>(
  VideoTransferNotifier.new,
);

class VideoTransferNotifier extends Notifier<VideoTransferState> {
  Timer? _pollTimer;

  @override
  VideoTransferState build() {
    ref.onDispose(() => _pollTimer?.cancel());
    return const VideoTransferState();
  }

  Future<void> submitJob({
    required File video,
    required String styleId,
    int sampleRate = 4,
    int maxFrames = 120,
    int? seed,
    int maxWorkers = 4,
    bool temporalSmoothing = true,
  }) async {
    state = const VideoTransferState(phase: VideoTransferPhase.uploading);
    try {
      final response = await ref.read(styleServiceProvider).submitVideoTransfer(
            video: video,
            styleId: styleId,
            sampleRate: sampleRate,
            maxFrames: maxFrames,
            seed: seed,
            maxWorkers: maxWorkers,
            temporalSmoothing: temporalSmoothing,
          );
      state = VideoTransferState(
        phase: VideoTransferPhase.processing,
        jobResponse: response,
      );
      _startPolling(response.jobId);
    } catch (e) {
      state = VideoTransferState(
        phase: VideoTransferPhase.failed,
        error: e.toString(),
      );
    }
  }

  Future<void> submitFastJob({
    required File video,
    required String styleId,
    int numKeyframes = 6,
    int? seed,
    int maxWorkers = 4,
  }) async {
    state = const VideoTransferState(phase: VideoTransferPhase.uploading);
    try {
      final response =
          await ref.read(styleServiceProvider).submitFastVideoTransfer(
                video: video,
                styleId: styleId,
                numKeyframes: numKeyframes,
                seed: seed,
                maxWorkers: maxWorkers,
              );
      state = VideoTransferState(
        phase: VideoTransferPhase.processing,
        jobResponse: response,
      );
      _startPolling(response.jobId);
    } catch (e) {
      state = VideoTransferState(
        phase: VideoTransferPhase.failed,
        error: e.toString(),
      );
    }
  }

  void _startPolling(String jobId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _poll(jobId),
    );
  }

  Future<void> _poll(String jobId) async {
    try {
      final status =
          await ref.read(styleServiceProvider).getVideoJobStatus(jobId);
      if (status.status == 'completed') {
        _pollTimer?.cancel();
        state = VideoTransferState(
          phase: VideoTransferPhase.completed,
          jobResponse: state.jobResponse,
          latestStatus: status,
        );
      } else if (status.status == 'failed') {
        _pollTimer?.cancel();
        state = VideoTransferState(
          phase: VideoTransferPhase.failed,
          jobResponse: state.jobResponse,
          latestStatus: status,
          error: status.error ?? 'Video transfer failed',
        );
      } else {
        state = state.copyWith(latestStatus: status);
      }
    } catch (_) {
      // Swallow transient network errors during polling
    }
  }

  void reset() {
    _pollTimer?.cancel();
    state = const VideoTransferState();
  }
}
