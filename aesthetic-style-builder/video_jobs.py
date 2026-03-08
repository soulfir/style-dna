import threading
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional


@dataclass
class VideoJob:
    job_id: str
    style_id: str
    status: str = "queued"  # queued, extracting, transferring, interpolating, assembling, completed, failed
    progress: float = 0.0
    total_frames: int = 0
    processed_frames: int = 0
    result_url: Optional[str] = None
    error: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.now)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    # For estimating time remaining
    _transfer_start_time: Optional[float] = field(default=None, repr=False)


class JobManager:
    """Thread-safe in-memory job store."""

    def __init__(self):
        self._jobs: dict[str, VideoJob] = {}
        self._lock = threading.Lock()

    def create_job(self, style_id: str) -> str:
        job_id = uuid.uuid4().hex[:12]
        job = VideoJob(job_id=job_id, style_id=style_id)
        with self._lock:
            self._jobs[job_id] = job
        return job_id

    def get_job(self, job_id: str) -> Optional[VideoJob]:
        with self._lock:
            return self._jobs.get(job_id)

    def update_job(self, job_id: str, **kwargs) -> None:
        with self._lock:
            job = self._jobs.get(job_id)
            if job is None:
                return
            for key, value in kwargs.items():
                setattr(job, key, value)

    def list_jobs(self) -> list[VideoJob]:
        with self._lock:
            return list(self._jobs.values())


# Singleton
_manager: Optional[JobManager] = None
_manager_lock = threading.Lock()


def get_job_manager() -> JobManager:
    global _manager
    if _manager is None:
        with _manager_lock:
            if _manager is None:
                _manager = JobManager()
    return _manager
