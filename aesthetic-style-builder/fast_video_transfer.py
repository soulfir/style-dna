"""Fast video style transfer using keyframe transfer + optical flow propagation.

Instead of transferring every Nth frame via API (slow), this pipeline:
1. Transfers only a few keyframes (3-10) via FLUX Kontext
2. Uses OpenCV optical flow to propagate the style to all other frames locally
3. Result: 5-10x fewer API calls, ~3x faster wall time
"""

import os
import random
import shutil
from typing import Callable, Optional

from create import compose_transfer_prompt, generate_transfer_image_raw
from models import AestheticProfile, VideoInfo
from optical_flow import compute_all_flows, propagate_style, select_keyframes
from utils import logger
from video_transfer import (
    FramePlan,
    extract_audio,
    extract_frames,
    get_video_info,
    reassemble_video,
    snap_to_flux_dims,
    transfer_frames_parallel,
    VIDEO_JOBS_DIR,
)


def run_fast_video_transfer_pipeline(
    video_path: str,
    profile: AestheticProfile,
    job_dir: str,
    num_keyframes: int = 6,
    seed: Optional[int] = None,
    max_workers: int = 4,
    flow_scale: float = 0.5,
    progress_callback: Optional[Callable[[str, float, int, int], None]] = None,
) -> str:
    """
    Fast video transfer pipeline using optical flow propagation.

    progress_callback(status, progress, processed_frames, total_frames)
    Returns path to output video.
    """
    def notify(status: str, progress: float, processed: int = 0, total: int = 0):
        if progress_callback:
            progress_callback(status, progress, processed, total)

    original_frames_dir = os.path.join(job_dir, "original_frames")
    styled_frames_dir = os.path.join(job_dir, "styled_frames")
    final_frames_dir = os.path.join(job_dir, "final_frames")
    audio_path = os.path.join(job_dir, "audio.aac")
    output_path = os.path.join(job_dir, "result.mp4")

    # 1. Get video info
    info = get_video_info(video_path)
    logger.info("Video info: %.1fs, %.1ffps, %dx%d, %d frames, audio=%s",
                info.duration, info.fps, info.width, info.height, info.total_frames, info.has_audio)

    # 2. Extract frames
    notify("extracting", 0.05)
    frame_count = extract_frames(video_path, original_frames_dir)
    logger.info("Extracted %d frames", frame_count)

    # 3. Extract audio
    has_audio = False
    if info.has_audio:
        has_audio = extract_audio(video_path, audio_path)
        logger.info("Audio extracted: %s", has_audio)

    # 4. Compute optical flows
    notify("computing_flow", 0.08)
    flows = compute_all_flows(
        frames_dir=original_frames_dir,
        frame_count=frame_count,
        scale=flow_scale,
        max_workers=max_workers,
    )
    logger.info("Computed %d optical flow fields", len(flows))

    # 5. Select keyframes
    actual_keyframes = min(num_keyframes, frame_count)
    keyframe_indices = select_keyframes(frame_count, actual_keyframes)
    logger.info("Selected %d keyframes: %s", len(keyframe_indices), keyframe_indices)
    notify("transferring", 0.15, 0, len(keyframe_indices))

    # 6. Compose transfer prompt ONCE
    prompt = compose_transfer_prompt(profile)
    logger.info("Transfer prompt composed (reusing for all keyframes)")

    # 7. Pick seed
    if seed is None:
        seed = random.randint(0, 2**32 - 1)
    logger.info("Using seed %d for all keyframes", seed)

    # 8. Compute FLUX-compatible dimensions
    flux_w, flux_h = snap_to_flux_dims(info.width, info.height)
    logger.info("FLUX dimensions: %dx%d (original %dx%d)", flux_w, flux_h, info.width, info.height)

    # 9. Transfer keyframes in parallel via FLUX Kontext
    plan = FramePlan(
        process_indices=keyframe_indices,
        total_frames=frame_count,
        effective_sample_rate=max(1, frame_count // len(keyframe_indices)),
    )

    def on_frame_progress(completed: int, total: int):
        p = 0.15 + (completed / total) * 0.55  # 15%-70%
        notify("transferring", p, completed, total)

    processed_frames = transfer_frames_parallel(
        prompt=prompt,
        frame_plan=plan,
        original_frames_dir=original_frames_dir,
        styled_frames_dir=styled_frames_dir,
        width=flux_w,
        height=flux_h,
        seed=seed,
        max_workers=max_workers,
        progress_callback=on_frame_progress,
    )
    logger.info("Transferred %d keyframes", len(processed_frames))

    # 10. Propagate style to all frames via optical flow
    notify("propagating", 0.72)
    propagate_style(
        keyframe_indices=keyframe_indices,
        styled_frames=processed_frames,
        flows=flows,
        total_frames=frame_count,
        output_dir=final_frames_dir,
    )
    logger.info("Propagated style to all %d frames", frame_count)

    # 11. Reassemble video
    notify("assembling", 0.92)
    reassemble_video(
        frame_dir=final_frames_dir,
        output_path=output_path,
        fps=info.fps,
        audio_path=audio_path if has_audio else None,
    )
    logger.info("Video assembled: %s", output_path)

    # 12. Cleanup intermediate files
    try:
        shutil.rmtree(original_frames_dir, ignore_errors=True)
        shutil.rmtree(styled_frames_dir, ignore_errors=True)
    except Exception:
        pass

    notify("completed", 1.0, len(keyframe_indices), len(keyframe_indices))
    return output_path
