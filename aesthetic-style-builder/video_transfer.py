import json
import os
import random
import shutil
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from typing import Callable, Optional

import numpy as np
from PIL import Image

from create import compose_transfer_prompt, generate_transfer_image_raw
from models import AestheticProfile, VideoInfo
from utils import logger

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(BASE_DIR, "output")
VIDEO_JOBS_DIR = os.path.join(OUTPUT_DIR, "video_jobs")


@dataclass
class FramePlan:
    process_indices: list[int]
    total_frames: int
    effective_sample_rate: int


def get_video_info(video_path: str) -> VideoInfo:
    """Use ffprobe to extract video metadata."""
    cmd = [
        "ffprobe", "-v", "quiet", "-print_format", "json",
        "-show_format", "-show_streams", video_path,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    data = json.loads(result.stdout)

    video_stream = None
    has_audio = False
    for stream in data.get("streams", []):
        if stream["codec_type"] == "video" and video_stream is None:
            video_stream = stream
        elif stream["codec_type"] == "audio":
            has_audio = True

    if video_stream is None:
        raise ValueError("No video stream found in file")

    # Parse FPS from r_frame_rate (e.g. "30/1" or "30000/1001")
    fps_parts = video_stream["r_frame_rate"].split("/")
    fps = float(fps_parts[0]) / float(fps_parts[1]) if len(fps_parts) == 2 else float(fps_parts[0])

    duration = float(data["format"]["duration"])
    width = int(video_stream["width"])
    height = int(video_stream["height"])
    total_frames = int(duration * fps)

    return VideoInfo(
        duration=duration,
        fps=fps,
        width=width,
        height=height,
        has_audio=has_audio,
        total_frames=total_frames,
    )


def extract_frames(video_path: str, output_dir: str, fps: Optional[float] = None) -> int:
    """Extract frames from video using ffmpeg. Returns frame count."""
    os.makedirs(output_dir, exist_ok=True)
    cmd = ["ffmpeg", "-i", video_path, "-vsync", "0"]
    if fps:
        cmd.extend(["-vf", f"fps={fps}"])
    cmd.extend([os.path.join(output_dir, "frame_%06d.png")])
    subprocess.run(cmd, capture_output=True, check=True)

    frames = sorted(f for f in os.listdir(output_dir) if f.startswith("frame_") and f.endswith(".png"))
    return len(frames)


def extract_audio(video_path: str, output_path: str) -> bool:
    """Extract audio track. Returns False if no audio."""
    cmd = [
        "ffmpeg", "-i", video_path, "-vn", "-acodec", "aac",
        "-b:a", "192k", output_path, "-y",
    ]
    result = subprocess.run(cmd, capture_output=True)
    return result.returncode == 0 and os.path.exists(output_path)


def compute_frame_plan(total_frames: int, sample_rate: int, max_frames: int) -> FramePlan:
    """Determine which frames to process vs interpolate."""
    effective_rate = max(sample_rate, total_frames // max_frames) if max_frames > 0 else sample_rate

    process_indices = list(range(0, total_frames, effective_rate))
    # Always include the last frame for clean interpolation
    if process_indices and process_indices[-1] != total_frames - 1:
        process_indices.append(total_frames - 1)

    # Cap at max_frames
    if len(process_indices) > max_frames:
        step = len(process_indices) / max_frames
        process_indices = [process_indices[int(i * step)] for i in range(max_frames)]
        if process_indices[-1] != total_frames - 1:
            process_indices[-1] = total_frames - 1

    return FramePlan(
        process_indices=process_indices,
        total_frames=total_frames,
        effective_sample_rate=effective_rate,
    )


def snap_to_flux_dims(width: int, height: int, max_dim: int = 2048) -> tuple[int, int]:
    """Snap dimensions to nearest FLUX-compatible values (multiple of 64, 256-2048)."""
    scale = 1.0
    if max(width, height) > max_dim:
        scale = max_dim / max(width, height)
    if min(width, height) * scale < 256:
        scale = 256 / min(width, height)

    w = max(256, min(max_dim, int(width * scale)))
    h = max(256, min(max_dim, int(height * scale)))
    # Round to nearest multiple of 64
    w = ((w + 32) // 64) * 64
    h = ((h + 32) // 64) * 64
    return max(256, min(max_dim, w)), max(256, min(max_dim, h))


def transfer_single_frame(
    prompt: str,
    frame_path: str,
    output_path: str,
    width: int,
    height: int,
    seed: int,
    style_source_image_path: Optional[str] = None,
) -> str:
    """Transfer a single frame and save to output_path."""
    image_data = generate_transfer_image_raw(
        prompt=prompt,
        image_path=frame_path,
        style_reference_image_path=style_source_image_path,
        width=width,
        height=height,
        seed=seed,
    )
    with open(output_path, "wb") as f:
        f.write(image_data)
    return output_path


def transfer_frames_parallel(
    prompt: str,
    frame_plan: FramePlan,
    original_frames_dir: str,
    styled_frames_dir: str,
    width: int,
    height: int,
    seed: int,
    style_source_image_path: Optional[str] = None,
    max_workers: int = 4,
    progress_callback: Optional[Callable[[int, int], None]] = None,
) -> dict[int, str]:
    """Process sampled frames in parallel. Returns {frame_index: output_path}."""
    os.makedirs(styled_frames_dir, exist_ok=True)
    total = len(frame_plan.process_indices)
    results: dict[int, str] = {}
    completed = 0

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {}
        for idx in frame_plan.process_indices:
            frame_name = f"frame_{idx + 1:06d}.png"  # ffmpeg starts at 1
            input_path = os.path.join(original_frames_dir, frame_name)
            output_path = os.path.join(styled_frames_dir, f"frame_{idx:06d}.png")

            future = executor.submit(
                transfer_single_frame,
                prompt=prompt,
                frame_path=input_path,
                output_path=output_path,
                width=width,
                height=height,
                seed=seed,
                style_source_image_path=style_source_image_path,
            )
            futures[future] = idx

        for future in as_completed(futures):
            idx = futures[future]
            try:
                path = future.result()
                results[idx] = path
            except Exception as e:
                logger.error("Failed to transfer frame %d: %s", idx, e)
                raise

            completed += 1
            if progress_callback:
                progress_callback(completed, total)

    return results


def interpolate_skipped_frames(
    processed_frames: dict[int, str],
    total_frames: int,
    output_dir: str,
) -> None:
    """Alpha-blend skipped frames from nearest processed neighbors."""
    os.makedirs(output_dir, exist_ok=True)

    sorted_indices = sorted(processed_frames.keys())

    # First copy all processed frames to output
    for idx in sorted_indices:
        src = processed_frames[idx]
        dst = os.path.join(output_dir, f"frame_{idx:06d}.png")
        if src != dst:
            shutil.copy2(src, dst)

    # Interpolate between each pair of processed frames
    for i in range(len(sorted_indices) - 1):
        start_idx = sorted_indices[i]
        end_idx = sorted_indices[i + 1]

        if end_idx - start_idx <= 1:
            continue  # No gap

        img_start = np.array(Image.open(processed_frames[start_idx]), dtype=np.float32)
        img_end = np.array(Image.open(processed_frames[end_idx]), dtype=np.float32)

        # Resize if dimensions don't match (shouldn't happen but be safe)
        if img_start.shape != img_end.shape:
            img_end_pil = Image.open(processed_frames[end_idx]).resize(
                (img_start.shape[1], img_start.shape[0]), Image.LANCZOS
            )
            img_end = np.array(img_end_pil, dtype=np.float32)

        gap = end_idx - start_idx
        for j in range(1, gap):
            alpha = j / gap
            blended = ((1.0 - alpha) * img_start + alpha * img_end).astype(np.uint8)
            frame_idx = start_idx + j
            out_path = os.path.join(output_dir, f"frame_{frame_idx:06d}.png")
            Image.fromarray(blended).save(out_path)

    # Handle frames before the first processed frame (duplicate first)
    if sorted_indices[0] > 0:
        first_path = processed_frames[sorted_indices[0]]
        for idx in range(0, sorted_indices[0]):
            dst = os.path.join(output_dir, f"frame_{idx:06d}.png")
            shutil.copy2(first_path, dst)

    # Handle frames after the last processed frame (duplicate last)
    if sorted_indices[-1] < total_frames - 1:
        last_path = processed_frames[sorted_indices[-1]]
        for idx in range(sorted_indices[-1] + 1, total_frames):
            dst = os.path.join(output_dir, f"frame_{idx:06d}.png")
            shutil.copy2(last_path, dst)


def temporal_smooth(frame_dir: str, total_frames: int) -> None:
    """Apply 5-tap temporal smoothing filter in-place using a sliding window to avoid OOM."""
    weights = [0.05, 0.2, 0.5, 0.2, 0.05]
    radius = 2
    window_size = 2 * radius + 1

    def load_frame(idx: int) -> np.ndarray:
        path = os.path.join(frame_dir, f"frame_{idx:06d}.png")
        if os.path.exists(path):
            return np.array(Image.open(path), dtype=np.float32)
        return None

    # Use a sliding window of only 5 frames in memory at a time
    # Write smoothed frames to temp files, then rename back
    tmp_dir = os.path.join(frame_dir, "_smooth_tmp")
    os.makedirs(tmp_dir, exist_ok=True)

    # Pre-load the initial window
    window = {}
    for i in range(min(window_size, total_frames)):
        frame = load_frame(i)
        if frame is not None:
            window[i] = frame

    for t in range(total_frames):
        # Ensure window has the frames we need
        for k in range(-radius, radius + 1):
            src_t = max(0, min(total_frames - 1, t + k))
            if src_t not in window:
                frame = load_frame(src_t)
                if frame is not None:
                    window[src_t] = frame

        if t not in window:
            continue

        result = np.zeros_like(window[t])
        weight_sum = 0.0
        for k in range(-radius, radius + 1):
            src_t = max(0, min(total_frames - 1, t + k))
            w = weights[k + radius]
            if src_t in window and window[src_t].shape == window[t].shape:
                result += w * window[src_t]
                weight_sum += w
        if weight_sum > 0:
            result /= weight_sum

        out_path = os.path.join(tmp_dir, f"frame_{t:06d}.png")
        Image.fromarray(result.astype(np.uint8)).save(out_path)

        # Evict frames we no longer need (older than t - radius)
        evict_before = t - radius
        for key in list(window.keys()):
            if key < evict_before:
                del window[key]

    # Move smoothed frames back
    for fname in os.listdir(tmp_dir):
        shutil.move(os.path.join(tmp_dir, fname), os.path.join(frame_dir, fname))
    shutil.rmtree(tmp_dir, ignore_errors=True)


def reassemble_video(
    frame_dir: str,
    output_path: str,
    fps: float,
    audio_path: Optional[str] = None,
) -> str:
    """Reassemble frames into video with optional audio."""
    cmd = [
        "ffmpeg", "-y",
        "-framerate", str(fps),
        "-i", os.path.join(frame_dir, "frame_%06d.png"),
    ]

    if audio_path and os.path.exists(audio_path):
        cmd.extend(["-i", audio_path, "-c:a", "aac", "-b:a", "192k", "-shortest"])

    cmd.extend([
        "-c:v", "libx264",
        "-crf", "18",
        "-pix_fmt", "yuv420p",
        output_path,
    ])

    subprocess.run(cmd, capture_output=True, check=True)
    return output_path


def run_video_transfer_pipeline(
    video_path: str,
    profile: AestheticProfile,
    job_dir: str,
    style_source_image_path: Optional[str] = None,
    sample_rate: int = 4,
    max_frames: int = 120,
    seed: Optional[int] = None,
    max_workers: int = 4,
    temporal_smoothing: bool = True,
    progress_callback: Optional[Callable[[str, float, int, int], None]] = None,
) -> str:
    """
    Full video transfer pipeline.

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

    # 4. Compute frame plan
    plan = compute_frame_plan(frame_count, sample_rate, max_frames)
    logger.info("Frame plan: %d frames to process (effective rate=%d)",
                len(plan.process_indices), plan.effective_sample_rate)
    notify("transferring", 0.10, 0, len(plan.process_indices))

    # 5. Compose transfer prompt ONCE
    prompt = compose_transfer_prompt(profile)
    logger.info("Transfer prompt composed (reusing for all frames)")

    # 6. Pick seed
    if seed is None:
        seed = random.randint(0, 2**32 - 1)
    logger.info("Using seed %d for all frames", seed)

    # 7. Compute FLUX-compatible dimensions
    flux_w, flux_h = snap_to_flux_dims(info.width, info.height)
    logger.info("FLUX dimensions: %dx%d (original %dx%d)", flux_w, flux_h, info.width, info.height)

    # 8. Transfer frames in parallel
    def on_frame_progress(completed: int, total: int):
        # Transferring takes 10%-85% of total progress
        p = 0.10 + (completed / total) * 0.75
        notify("transferring", p, completed, total)

    processed_frames = transfer_frames_parallel(
        prompt=prompt,
        frame_plan=plan,
        original_frames_dir=original_frames_dir,
        styled_frames_dir=styled_frames_dir,
        width=flux_w,
        height=flux_h,
        seed=seed,
        style_source_image_path=style_source_image_path,
        max_workers=max_workers,
        progress_callback=on_frame_progress,
    )
    logger.info("Transferred %d frames", len(processed_frames))

    # 9. Interpolate skipped frames
    notify("interpolating", 0.87)
    interpolate_skipped_frames(processed_frames, frame_count, final_frames_dir)
    logger.info("Interpolated all %d frames", frame_count)

    # 10. Optional temporal smoothing
    if temporal_smoothing:
        notify("smoothing", 0.92)
        temporal_smooth(final_frames_dir, frame_count)
        logger.info("Temporal smoothing applied")

    # 11. Reassemble video
    notify("assembling", 0.95)
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

    notify("completed", 1.0, len(plan.process_indices), len(plan.process_indices))
    return output_path
