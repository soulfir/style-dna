import os
import shutil
from concurrent.futures import ThreadPoolExecutor
from typing import Optional

import cv2
import numpy as np
from PIL import Image

from utils import logger


def _load_gray(path: str, scale: float = 1.0) -> np.ndarray:
    """Load an image as grayscale, optionally scaled down."""
    img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        raise FileNotFoundError(f"Cannot read image: {path}")
    if scale != 1.0:
        h, w = img.shape[:2]
        img = cv2.resize(img, (int(w * scale), int(h * scale)), interpolation=cv2.INTER_AREA)
    return img


def _load_color(path: str) -> np.ndarray:
    """Load an image in BGR color."""
    img = cv2.imread(path, cv2.IMREAD_COLOR)
    if img is None:
        raise FileNotFoundError(f"Cannot read image: {path}")
    return img


def compute_pairwise_flow(
    prev_gray: np.ndarray,
    next_gray: np.ndarray,
) -> np.ndarray:
    """Compute optical flow from prev to next frame using Farneback."""
    return cv2.calcOpticalFlowFarneback(
        prev_gray, next_gray,
        flow=None,
        pyr_scale=0.5,
        levels=5,
        winsize=15,
        iterations=3,
        poly_n=7,
        poly_sigma=1.5,
        flags=0,
    )


def compute_all_flows(
    frames_dir: str,
    frame_count: int,
    scale: float = 0.5,
    max_workers: int = 4,
) -> list[np.ndarray]:
    """Compute forward optical flows for all consecutive frame pairs.

    Returns list of flows where flows[i] is flow from frame i to frame i+1.
    Flows are computed at `scale` resolution for speed, then scaled up.
    """
    grays = []
    for i in range(frame_count):
        path = os.path.join(frames_dir, f"frame_{i + 1:06d}.png")  # ffmpeg 1-indexed
        grays.append(_load_gray(path, scale))

    logger.info("Computing optical flows for %d frame pairs at %.0f%% scale", frame_count - 1, scale * 100)

    def compute_pair(i: int) -> tuple[int, np.ndarray]:
        flow = compute_pairwise_flow(grays[i], grays[i + 1])
        if scale != 1.0:
            h, w = flow.shape[:2]
            orig_h = int(h / scale)
            orig_w = int(w / scale)
            flow = cv2.resize(flow, (orig_w, orig_h), interpolation=cv2.INTER_LINEAR)
            flow *= (1.0 / scale)
        return i, flow

    flows: list[Optional[np.ndarray]] = [None] * (frame_count - 1)

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        for i, flow in executor.map(lambda idx: compute_pair(idx), range(frame_count - 1)):
            flows[i] = flow

    return flows  # type: ignore


def _warp_flow(flow: np.ndarray, displacement: np.ndarray) -> np.ndarray:
    """Warp a flow field by a displacement field using remap."""
    h, w = flow.shape[:2]
    coords_x, coords_y = np.meshgrid(np.arange(w, dtype=np.float32), np.arange(h, dtype=np.float32))
    map_x = coords_x + displacement[..., 0]
    map_y = coords_y + displacement[..., 1]
    warped_x = cv2.remap(flow[..., 0], map_x, map_y, cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
    warped_y = cv2.remap(flow[..., 1], map_x, map_y, cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
    return np.stack([warped_x, warped_y], axis=-1)


def warp_image(image: np.ndarray, flow: np.ndarray) -> np.ndarray:
    """Warp an image using an accumulated flow field."""
    h, w = flow.shape[:2]
    if image.shape[0] != h or image.shape[1] != w:
        image = cv2.resize(image, (w, h), interpolation=cv2.INTER_LINEAR)

    coords_x, coords_y = np.meshgrid(np.arange(w, dtype=np.float32), np.arange(h, dtype=np.float32))
    map_x = coords_x + flow[..., 0]
    map_y = coords_y + flow[..., 1]
    return cv2.remap(image, map_x, map_y, cv2.INTER_LINEAR, borderMode=cv2.BORDER_REFLECT)


def select_keyframes(
    frame_count: int,
    num_keyframes: int = 6,
) -> list[int]:
    """Select evenly-spaced keyframes, always including first and last."""
    if num_keyframes >= frame_count:
        return list(range(frame_count))
    if num_keyframes <= 1:
        return [0]
    if num_keyframes == 2:
        return [0, frame_count - 1]

    indices = [0]
    step = (frame_count - 1) / (num_keyframes - 1)
    for i in range(1, num_keyframes - 1):
        indices.append(round(i * step))
    indices.append(frame_count - 1)
    return indices


def propagate_style(
    keyframe_indices: list[int],
    styled_frames: dict[int, str],
    flows: list[np.ndarray],
    total_frames: int,
    output_dir: str,
) -> None:
    """Propagate style from keyframes to all frames using optical flow warping.

    Bidirectional warp + distance-weighted blend between keyframes.
    """
    os.makedirs(output_dir, exist_ok=True)

    sorted_keys = sorted(keyframe_indices)

    # Load styled keyframe images (BGR)
    styled_images: dict[int, np.ndarray] = {}
    for idx in sorted_keys:
        styled_images[idx] = _load_color(styled_frames[idx])

    # Copy keyframes directly to output
    for idx in sorted_keys:
        src = styled_frames[idx]
        dst = os.path.join(output_dir, f"frame_{idx:06d}.png")
        if src != dst:
            shutil.copy2(src, dst)

    # Process each segment between consecutive keyframes
    for seg_i in range(len(sorted_keys) - 1):
        k_prev = sorted_keys[seg_i]
        k_next = sorted_keys[seg_i + 1]

        if k_next - k_prev <= 1:
            continue

        img_prev = styled_images[k_prev]
        img_next = styled_images[k_next]

        # Precompute backward accumulated flows from k_next
        bwd_flows_cache: dict[int, np.ndarray] = {}
        bwd_acc = -flows[k_next - 1].copy()
        bwd_flows_cache[k_next - 1] = bwd_acc.copy()
        for j in range(k_next - 2, k_prev, -1):
            inv_flow = -flows[j]
            bwd_acc = _warp_flow(bwd_acc, inv_flow) + inv_flow
            bwd_flows_cache[j] = bwd_acc.copy()

        # Forward accumulate and blend each intermediate frame
        fwd_acc = flows[k_prev].copy()
        for frame_idx in range(k_prev + 1, k_next):
            alpha = (frame_idx - k_prev) / (k_next - k_prev)

            warped_prev = warp_image(img_prev, fwd_acc)
            warped_next = warp_image(img_next, bwd_flows_cache[frame_idx])

            blended = ((1.0 - alpha) * warped_prev + alpha * warped_next).astype(np.uint8)

            out_path = os.path.join(output_dir, f"frame_{frame_idx:06d}.png")
            cv2.imwrite(out_path, blended)

            # Advance forward accumulation
            if frame_idx < k_next - 1:
                next_flow = flows[frame_idx]
                fwd_acc = _warp_flow(fwd_acc, next_flow) + next_flow

    # Frames before first keyframe: backward warp from first keyframe
    if sorted_keys[0] > 0:
        first_styled = styled_images[sorted_keys[0]]
        acc = -flows[sorted_keys[0] - 1].copy()
        for idx in range(sorted_keys[0] - 1, -1, -1):
            warped = warp_image(first_styled, acc)
            cv2.imwrite(os.path.join(output_dir, f"frame_{idx:06d}.png"), warped)
            if idx > 0:
                inv_flow = -flows[idx - 1]
                acc = _warp_flow(acc, inv_flow) + inv_flow

    # Frames after last keyframe: forward warp from last keyframe
    if sorted_keys[-1] < total_frames - 1:
        last_styled = styled_images[sorted_keys[-1]]
        acc = flows[sorted_keys[-1]].copy()
        for idx in range(sorted_keys[-1] + 1, total_frames):
            warped = warp_image(last_styled, acc)
            cv2.imwrite(os.path.join(output_dir, f"frame_{idx:06d}.png"), warped)
            if idx < total_frames - 1:
                next_flow = flows[idx]
                acc = _warp_flow(acc, next_flow) + next_flow

    logger.info("Style propagated to all %d frames via optical flow", total_frames)
