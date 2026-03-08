import json
import os
import re
import time
import uuid
from datetime import datetime
from typing import Optional

from fastapi import BackgroundTasks, FastAPI, File, Form, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from models import (
    AestheticProfile,
    AnalyzeResponse,
    CreateRequest,
    CreateResponse,
    StyleListResponse,
    StyleReference,
    VideoJobStatus,
    VideoTransferResponse,
)
from fast_video_transfer import run_fast_video_transfer_pipeline
from video_jobs import get_job_manager
from video_transfer import get_video_info, run_video_transfer_pipeline, VIDEO_JOBS_DIR
from workflow import style_workflow
from utils import logger

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(BASE_DIR, "uploads")
OUTPUT_DIR = os.path.join(BASE_DIR, "output")

MAX_UPLOAD_SIZE = 10 * 1024 * 1024  # 10MB
MAX_VIDEO_UPLOAD_SIZE = 100 * 1024 * 1024  # 100MB
MAX_VIDEO_DURATION = float(os.getenv("MAX_VIDEO_DURATION", "60"))
ALLOWED_VIDEO_EXTENSIONS = {".mp4", ".mov", ".webm", ".avi", ".mkv"}

os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(VIDEO_JOBS_DIR, exist_ok=True)

app = FastAPI(title="Aesthetic Style Builder", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/output", StaticFiles(directory=OUTPUT_DIR), name="output")
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


@app.on_event("startup")
async def startup_checks():
    api_key = os.getenv("TOGETHER_API_KEY")
    if not api_key:
        logger.error("TOGETHER_API_KEY is not set — API calls will fail")
        raise RuntimeError("TOGETHER_API_KEY environment variable is required")
    logger.info("Aesthetic Style Builder started")


def _sanitize_filename(filename: str) -> str:
    """Generate a safe filename using UUID, preserving only the extension."""
    basename = os.path.basename(filename)
    _, ext = os.path.splitext(basename)
    ext = re.sub(r"[^a-zA-Z0-9.]", "", ext)[:10]
    if not ext:
        ext = ".jpg"
    return f"{uuid.uuid4().hex}{ext}"


async def save_upload(file: UploadFile) -> str:
    contents = await file.read()
    if len(contents) > MAX_UPLOAD_SIZE:
        raise HTTPException(status_code=413, detail="File too large (max 10MB)")

    filename = _sanitize_filename(file.filename or "upload.jpg")
    dest = os.path.join(UPLOAD_DIR, filename)
    with open(dest, "wb") as f:
        f.write(contents)
    logger.info("Saved upload: %s", filename)
    return dest


@app.post("/analyze", response_model=AnalyzeResponse)
async def analyze_endpoint(
    file: UploadFile = File(...),
    custom_tag: Optional[str] = Form(None),
):
    logger.info("POST /analyze")
    image_path = await save_upload(file)

    result = style_workflow.run(
        input=json.dumps({
            "type": "analyze",
            "image_path": image_path,
            "custom_tag": custom_tag,
        })
    )

    content = getattr(result, "content", None)
    if content is None:
        content = getattr(result, "output", None) or str(result)

    data = json.loads(content)
    ref = StyleReference(**data["ref"])

    return AnalyzeResponse(
        style=ref, message=f"Style '{ref.style_tag}' extracted and saved"
    )


@app.post("/create", response_model=CreateResponse)
async def create_endpoint(
    style_ids: str = Form(...),
    prompt: Optional[str] = Form(None),
    seed: Optional[int] = Form(None),
    width: int = Form(1024),
    height: int = Form(1024),
    reference_image: Optional[UploadFile] = File(None),
):
    try:
        ids = json.loads(style_ids)
    except (json.JSONDecodeError, TypeError) as e:
        raise HTTPException(status_code=400, detail=f"Invalid style_ids JSON: {e}")

    if not ids:
        raise HTTPException(status_code=400, detail="style_ids list cannot be empty")
    if len(ids) > 5:
        raise HTTPException(status_code=400, detail="Maximum 5 style_ids allowed")

    logger.info("POST /create with %d style(s)", len(ids))

    # Gather profiles and source image paths from style library via workflow
    profiles = []
    style_source_image_paths = []
    for sid in ids:
        result = style_workflow.run(
            input=json.dumps({"type": "get_style", "style_id": sid})
        )
        content = getattr(result, "content", None)
        if content is None:
            content = getattr(result, "output", None) or str(result)
        style_data = json.loads(content)
        if "error" in style_data:
            raise HTTPException(status_code=404, detail=f"Style '{sid}' not found")
        profiles.append(style_data["profile"])
        style_source_image_paths.append(style_data.get("source_image_path"))

    ref_image_path = None
    if reference_image and reference_image.filename:
        ref_image_path = await save_upload(reference_image)

    result = style_workflow.run(
        input=json.dumps({
            "type": "create",
            "profiles": profiles,
            "user_prompt": prompt,
            "reference_image_path": ref_image_path,
            "style_source_image_paths": style_source_image_paths,
            "width": width,
            "height": height,
            "seed": seed,
        })
    )

    content = getattr(result, "content", None)
    if content is None:
        content = getattr(result, "output", None) or str(result)

    data = json.loads(content)

    return CreateResponse(
        image_url=f"/output/{data['filename']}",
        prompt_used=data["prompt_used"],
        message="Image generated successfully",
    )


@app.post("/transfer", response_model=CreateResponse)
async def transfer_endpoint(
    image: UploadFile = File(...),
    style_id: str = Form(...),
    seed: Optional[int] = Form(None),
    width: int = Form(1024),
    height: int = Form(1024),
):
    logger.info("POST /transfer with style_id=%s", style_id)

    if width < 256 or width > 2048 or width % 64 != 0:
        raise HTTPException(status_code=400, detail="width must be 256-2048 and a multiple of 64")
    if height < 256 or height > 2048 or height % 64 != 0:
        raise HTTPException(status_code=400, detail="height must be 256-2048 and a multiple of 64")
    if seed is not None and seed < 0:
        raise HTTPException(status_code=400, detail="seed must be non-negative")

    image_path = await save_upload(image)

    # Look up the style
    result = style_workflow.run(
        input=json.dumps({"type": "get_style", "style_id": style_id})
    )
    content = getattr(result, "content", None)
    if content is None:
        content = getattr(result, "output", None) or str(result)
    style_data = json.loads(content)
    if "error" in style_data:
        raise HTTPException(status_code=404, detail=f"Style '{style_id}' not found")

    # Dispatch the transfer
    result = style_workflow.run(
        input=json.dumps({
            "type": "transfer",
            "profile": style_data["profile"],
            "image_path": image_path,
            "style_source_image_path": style_data.get("source_image_path"),
            "width": width,
            "height": height,
            "seed": seed,
        })
    )

    content = getattr(result, "content", None)
    if content is None:
        content = getattr(result, "output", None) or str(result)

    data = json.loads(content)

    return CreateResponse(
        image_url=f"/output/{data['filename']}",
        prompt_used=data["prompt_used"],
        message="Style transfer completed successfully",
    )


@app.get("/styles", response_model=StyleListResponse)
async def list_styles():
    logger.info("GET /styles")
    result = style_workflow.run(
        input=json.dumps({"type": "list_styles"})
    )
    content = getattr(result, "content", None)
    if content is None:
        content = getattr(result, "output", None) or str(result)
    data = json.loads(content)
    refs = [StyleReference(**s) for s in data["styles"]]
    return StyleListResponse(styles=refs, count=len(refs))


@app.get("/styles/{style_id}", response_model=StyleReference)
async def get_style(style_id: str):
    logger.info("GET /styles/%s", style_id)
    result = style_workflow.run(
        input=json.dumps({"type": "get_style", "style_id": style_id})
    )
    content = getattr(result, "content", None)
    if content is None:
        content = getattr(result, "output", None) or str(result)
    data = json.loads(content)
    if "error" in data:
        raise HTTPException(status_code=404, detail="Style not found")
    return StyleReference(**data)


@app.delete("/styles/{style_id}")
async def delete_style(style_id: str):
    logger.info("DELETE /styles/%s", style_id)
    result = style_workflow.run(
        input=json.dumps({"type": "delete_style", "style_id": style_id})
    )
    content = getattr(result, "content", None)
    if content is None:
        content = getattr(result, "output", None) or str(result)
    data = json.loads(content)
    if "error" in data:
        raise HTTPException(status_code=404, detail="Style not found")
    return {"message": f"Style '{style_id}' deleted"}


# --- Video Transfer Endpoints ---

async def _save_video_upload(file: UploadFile) -> str:
    """Save a video upload with size validation."""
    contents = await file.read()
    if len(contents) > MAX_VIDEO_UPLOAD_SIZE:
        raise HTTPException(status_code=413, detail="Video too large (max 100MB)")

    filename = _sanitize_filename(file.filename or "upload.mp4")
    dest = os.path.join(UPLOAD_DIR, filename)
    with open(dest, "wb") as f:
        f.write(contents)
    logger.info("Saved video upload: %s (%d bytes)", filename, len(contents))
    return dest


def _run_video_transfer_background(
    job_id: str,
    video_path: str,
    profile: AestheticProfile,
    style_source_image_path: Optional[str],
    sample_rate: int,
    max_frames: int,
    seed: Optional[int],
    max_workers: int,
    temporal_smoothing: bool,
):
    """Background task for video transfer."""
    job_manager = get_job_manager()
    job_dir = os.path.join(VIDEO_JOBS_DIR, job_id)
    os.makedirs(job_dir, exist_ok=True)

    job_manager.update_job(job_id, started_at=datetime.now(), _transfer_start_time=time.time())

    def on_progress(status: str, progress: float, processed: int, total: int):
        job_manager.update_job(
            job_id,
            status=status,
            progress=progress,
            processed_frames=processed,
            total_frames=total,
        )

    try:
        output_path = run_video_transfer_pipeline(
            video_path=video_path,
            profile=profile,
            job_dir=job_dir,
            style_source_image_path=style_source_image_path,
            sample_rate=sample_rate,
            max_frames=max_frames,
            seed=seed,
            max_workers=max_workers,
            temporal_smoothing=temporal_smoothing,
            progress_callback=on_progress,
        )

        result_url = f"/output/video_jobs/{job_id}/result.mp4"
        job_manager.update_job(
            job_id,
            status="completed",
            progress=1.0,
            result_url=result_url,
            completed_at=datetime.now(),
        )
        logger.info("Video transfer job %s completed: %s", job_id, result_url)

    except Exception as e:
        logger.error("Video transfer job %s failed: %s", job_id, e)
        job_manager.update_job(
            job_id,
            status="failed",
            error=str(e),
            completed_at=datetime.now(),
        )


@app.post("/transfer/video", response_model=VideoTransferResponse)
async def transfer_video_endpoint(
    background_tasks: BackgroundTasks,
    video: UploadFile = File(...),
    style_id: str = Form(...),
    sample_rate: int = Form(4),
    max_frames: int = Form(120),
    seed: Optional[int] = Form(None),
    max_workers: int = Form(4),
    temporal_smoothing: bool = Form(True),
):
    """Start a video style transfer job. Returns immediately with job_id."""
    logger.info("POST /transfer/video with style_id=%s", style_id)

    # Validate file extension
    ext = os.path.splitext(video.filename or "")[1].lower()
    if ext not in ALLOWED_VIDEO_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported video format '{ext}'. Allowed: {', '.join(ALLOWED_VIDEO_EXTENSIONS)}",
        )

    # Validate parameters
    if sample_rate < 1 or sample_rate > 30:
        raise HTTPException(status_code=400, detail="sample_rate must be 1-30")
    if max_frames < 10 or max_frames > 500:
        raise HTTPException(status_code=400, detail="max_frames must be 10-500")
    if max_workers < 1 or max_workers > 8:
        raise HTTPException(status_code=400, detail="max_workers must be 1-8")
    if seed is not None and seed < 0:
        raise HTTPException(status_code=400, detail="seed must be non-negative")

    # Save the video
    video_path = await _save_video_upload(video)

    # Get video info and validate duration
    try:
        info = get_video_info(video_path)
    except Exception as e:
        os.unlink(video_path)
        raise HTTPException(status_code=400, detail=f"Cannot read video file: {e}")

    if info.duration > MAX_VIDEO_DURATION:
        os.unlink(video_path)
        raise HTTPException(
            status_code=400,
            detail=f"Video too long ({info.duration:.1f}s). Max duration: {MAX_VIDEO_DURATION:.0f}s",
        )

    # Look up the style
    result = style_workflow.run(
        input=json.dumps({"type": "get_style", "style_id": style_id})
    )
    content = getattr(result, "content", None)
    if content is None:
        content = getattr(result, "output", None) or str(result)
    style_data = json.loads(content)
    if "error" in style_data:
        os.unlink(video_path)
        raise HTTPException(status_code=404, detail=f"Style '{style_id}' not found")

    profile = AestheticProfile(**style_data["profile"])
    style_source_image_path = style_data.get("source_image_path")

    # Estimate duration
    frames_to_process = min(max_frames, info.total_frames // sample_rate + 1)
    estimated_seconds = (frames_to_process / max_workers) * 4.0 + 15  # ~4s per API call + overhead

    # Create job
    job_manager = get_job_manager()
    job_id = job_manager.create_job(style_id=style_id)
    job_manager.update_job(job_id, total_frames=frames_to_process)

    # Launch background task
    background_tasks.add_task(
        _run_video_transfer_background,
        job_id=job_id,
        video_path=video_path,
        profile=profile,
        style_source_image_path=style_source_image_path,
        sample_rate=sample_rate,
        max_frames=max_frames,
        seed=seed,
        max_workers=max_workers,
        temporal_smoothing=temporal_smoothing,
    )

    return VideoTransferResponse(
        job_id=job_id,
        message="Video transfer job started",
        estimated_duration=estimated_seconds,
        video_info=info,
    )


@app.get("/transfer/video/jobs", response_model=list[VideoJobStatus])
async def list_video_jobs():
    """List all video transfer jobs."""
    job_manager = get_job_manager()
    jobs = job_manager.list_jobs()
    return [
        VideoJobStatus(
            job_id=j.job_id,
            status=j.status,
            progress=j.progress,
            total_frames=j.total_frames,
            processed_frames=j.processed_frames,
            style_id=j.style_id,
            result_url=j.result_url,
            error=j.error,
        )
        for j in jobs
    ]


@app.get("/transfer/video/{job_id}", response_model=VideoJobStatus)
async def get_video_job_status(job_id: str):
    """Get status of a video transfer job."""
    job_manager = get_job_manager()
    job = job_manager.get_job(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail=f"Job '{job_id}' not found")

    # Estimate time remaining
    estimated_remaining = None
    if job.status == "transferring" and job._transfer_start_time and job.processed_frames > 0:
        elapsed = time.time() - job._transfer_start_time
        rate = job.processed_frames / elapsed
        remaining_frames = job.total_frames - job.processed_frames
        if rate > 0:
            estimated_remaining = remaining_frames / rate

    return VideoJobStatus(
        job_id=job.job_id,
        status=job.status,
        progress=job.progress,
        total_frames=job.total_frames,
        processed_frames=job.processed_frames,
        style_id=job.style_id,
        result_url=job.result_url,
        error=job.error,
        estimated_time_remaining=estimated_remaining,
    )


# --- Fast Video Transfer Endpoint (Optical Flow) ---

def _run_fast_video_transfer_background(
    job_id: str,
    video_path: str,
    profile: AestheticProfile,
    num_keyframes: int,
    seed: Optional[int],
    max_workers: int,
):
    """Background task for fast video transfer."""
    job_manager = get_job_manager()
    job_dir = os.path.join(VIDEO_JOBS_DIR, job_id)
    os.makedirs(job_dir, exist_ok=True)

    job_manager.update_job(job_id, started_at=datetime.now(), _transfer_start_time=time.time())

    def on_progress(status: str, progress: float, processed: int, total: int):
        job_manager.update_job(
            job_id,
            status=status,
            progress=progress,
            processed_frames=processed,
            total_frames=total,
        )

    try:
        run_fast_video_transfer_pipeline(
            video_path=video_path,
            profile=profile,
            job_dir=job_dir,
            num_keyframes=num_keyframes,
            seed=seed,
            max_workers=max_workers,
            progress_callback=on_progress,
        )

        result_url = f"/output/video_jobs/{job_id}/result.mp4"
        job_manager.update_job(
            job_id,
            status="completed",
            progress=1.0,
            result_url=result_url,
            completed_at=datetime.now(),
        )
        logger.info("Fast video transfer job %s completed: %s", job_id, result_url)

    except Exception as e:
        logger.error("Fast video transfer job %s failed: %s", job_id, e)
        job_manager.update_job(
            job_id,
            status="failed",
            error=str(e),
            completed_at=datetime.now(),
        )


@app.post("/transfer/video/fast", response_model=VideoTransferResponse)
async def fast_transfer_video_endpoint(
    background_tasks: BackgroundTasks,
    video: UploadFile = File(...),
    style_id: str = Form(...),
    num_keyframes: int = Form(6),
    seed: Optional[int] = Form(None),
    max_workers: int = Form(4),
):
    """Fast video style transfer using optical flow propagation.

    Only transfers a few keyframes via FLUX Kontext, then propagates the style
    to all other frames using local optical flow warping. 3-5x faster than
    the standard /transfer/video endpoint.
    """
    logger.info("POST /transfer/video/fast with style_id=%s, keyframes=%d", style_id, num_keyframes)

    # Validate file extension
    ext = os.path.splitext(video.filename or "")[1].lower()
    if ext not in ALLOWED_VIDEO_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported video format '{ext}'. Allowed: {', '.join(ALLOWED_VIDEO_EXTENSIONS)}",
        )

    # Validate parameters
    if num_keyframes < 2 or num_keyframes > 20:
        raise HTTPException(status_code=400, detail="num_keyframes must be 2-20")
    if max_workers < 1 or max_workers > 8:
        raise HTTPException(status_code=400, detail="max_workers must be 1-8")
    if seed is not None and seed < 0:
        raise HTTPException(status_code=400, detail="seed must be non-negative")

    # Save the video
    video_path = await _save_video_upload(video)

    # Get video info and validate duration
    try:
        info = get_video_info(video_path)
    except Exception as e:
        os.unlink(video_path)
        raise HTTPException(status_code=400, detail=f"Cannot read video file: {e}")

    if info.duration > MAX_VIDEO_DURATION:
        os.unlink(video_path)
        raise HTTPException(
            status_code=400,
            detail=f"Video too long ({info.duration:.1f}s). Max duration: {MAX_VIDEO_DURATION:.0f}s",
        )

    # Look up the style
    result = style_workflow.run(
        input=json.dumps({"type": "get_style", "style_id": style_id})
    )
    content = getattr(result, "content", None)
    if content is None:
        content = getattr(result, "output", None) or str(result)
    style_data = json.loads(content)
    if "error" in style_data:
        os.unlink(video_path)
        raise HTTPException(status_code=404, detail=f"Style '{style_id}' not found")

    profile = AestheticProfile(**style_data["profile"])

    # Estimate duration: keyframe API calls + flow computation + propagation
    api_time = (num_keyframes / max_workers) * 4.0
    flow_time = info.total_frames * 0.05  # ~50ms per frame pair
    propagation_time = info.total_frames * 0.06
    estimated_seconds = api_time + flow_time + propagation_time + 10  # +overhead

    # Create job
    job_manager = get_job_manager()
    job_id = job_manager.create_job(style_id=style_id)
    job_manager.update_job(job_id, total_frames=num_keyframes)

    # Launch background task
    background_tasks.add_task(
        _run_fast_video_transfer_background,
        job_id=job_id,
        video_path=video_path,
        profile=profile,
        num_keyframes=num_keyframes,
        seed=seed,
        max_workers=max_workers,
    )

    return VideoTransferResponse(
        job_id=job_id,
        message="Fast video transfer job started (optical flow mode)",
        estimated_duration=estimated_seconds,
        video_info=info,
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
