from pydantic import BaseModel, field_validator
from typing import List, Optional, Literal


class ColorGrading(BaseModel):
    dominant_colors: List[str]
    palette_type: Literal["warm", "cool", "neutral", "mixed"]
    color_temperature: str
    saturation: Literal["low", "medium", "high", "vivid"]


class Lighting(BaseModel):
    direction: str
    quality: Literal["hard", "soft", "diffused", "mixed"]
    contrast_ratio: Literal["low", "medium", "high", "extreme"]
    mood: str


class Texture(BaseModel):
    grain: Literal["none", "fine", "medium", "heavy"]
    surface_quality: str
    sharpness: Literal["soft", "moderate", "sharp", "crisp"]


class Composition(BaseModel):
    technique: str
    depth_layers: Literal["flat", "shallow", "medium", "deep"]
    framing: str


class Contrast(BaseModel):
    dynamic_range: Literal["compressed", "normal", "wide", "HDR"]
    shadow_depth: Literal["lifted", "medium", "deep", "crushed"]
    highlight_character: str


class Atmosphere(BaseModel):
    mood: str
    emotional_tone: str
    genre: str


class AestheticProfile(BaseModel):
    style_tag: str
    color_grading: ColorGrading
    lighting: Lighting
    texture: Texture
    composition: Composition
    contrast: Contrast
    atmosphere: Atmosphere


class StyleReference(BaseModel):
    id: str
    style_tag: str
    profile: AestheticProfile
    source_image_path: Optional[str] = None
    created_at: str


class AnalyzeResponse(BaseModel):
    style: StyleReference
    message: str


class CreateRequest(BaseModel):
    style_ids: List[str]
    prompt: Optional[str] = None
    seed: Optional[int] = None
    width: int = 1024
    height: int = 1024

    @field_validator("style_ids")
    @classmethod
    def validate_style_ids(cls, v):
        if not v:
            raise ValueError("style_ids must not be empty")
        if len(v) > 5:
            raise ValueError("Maximum 5 style_ids allowed")
        return v

    @field_validator("width", "height")
    @classmethod
    def validate_dimensions(cls, v):
        if v < 256 or v > 2048:
            raise ValueError("Dimensions must be between 256 and 2048")
        if v % 64 != 0:
            raise ValueError("Dimensions must be a multiple of 64")
        return v

    @field_validator("seed")
    @classmethod
    def validate_seed(cls, v):
        if v is not None and v < 0:
            raise ValueError("Seed must be non-negative")
        return v


class CreateResponse(BaseModel):
    image_url: str
    prompt_used: str
    message: str


class StyleListResponse(BaseModel):
    styles: List[StyleReference]
    count: int


# --- Video Transfer Models ---

class VideoInfo(BaseModel):
    duration: float
    fps: float
    width: int
    height: int
    has_audio: bool
    total_frames: int


class VideoJobStatus(BaseModel):
    job_id: str
    status: str
    progress: float
    total_frames: int
    processed_frames: int
    style_id: str
    result_url: Optional[str] = None
    error: Optional[str] = None
    estimated_time_remaining: Optional[float] = None


class VideoTransferResponse(BaseModel):
    job_id: str
    message: str
    estimated_duration: float
    video_info: VideoInfo
