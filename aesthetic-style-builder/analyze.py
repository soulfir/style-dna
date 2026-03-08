import json
import os

from fastapi import HTTPException

from models import AestheticProfile
from utils import get_together_client, encode_image, retry, logger

VISION_MODEL = os.getenv("VISION_MODEL", "meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8")

AESTHETIC_SCHEMA = {
    "type": "object",
    "properties": {
        "style_tag": {
            "type": "string",
            "description": "A concise 2-4 word descriptor capturing the overall aesthetic",
        },
        "color_grading": {
            "type": "object",
            "properties": {
                "dominant_colors": {"type": "array", "items": {"type": "string"}},
                "palette_type": {
                    "type": "string",
                    "enum": ["warm", "cool", "neutral", "mixed"],
                },
                "color_temperature": {"type": "string"},
                "saturation": {
                    "type": "string",
                    "enum": ["low", "medium", "high", "vivid"],
                },
            },
            "required": [
                "dominant_colors",
                "palette_type",
                "color_temperature",
                "saturation",
            ],
        },
        "lighting": {
            "type": "object",
            "properties": {
                "direction": {"type": "string"},
                "quality": {
                    "type": "string",
                    "enum": ["hard", "soft", "diffused", "mixed"],
                },
                "contrast_ratio": {
                    "type": "string",
                    "enum": ["low", "medium", "high", "extreme"],
                },
                "mood": {"type": "string"},
            },
            "required": ["direction", "quality", "contrast_ratio", "mood"],
        },
        "texture": {
            "type": "object",
            "properties": {
                "grain": {
                    "type": "string",
                    "enum": ["none", "fine", "medium", "heavy"],
                },
                "surface_quality": {"type": "string"},
                "sharpness": {
                    "type": "string",
                    "enum": ["soft", "moderate", "sharp", "crisp"],
                },
            },
            "required": ["grain", "surface_quality", "sharpness"],
        },
        "composition": {
            "type": "object",
            "properties": {
                "technique": {"type": "string"},
                "depth_layers": {
                    "type": "string",
                    "enum": ["flat", "shallow", "medium", "deep"],
                },
                "framing": {"type": "string"},
            },
            "required": ["technique", "depth_layers", "framing"],
        },
        "contrast": {
            "type": "object",
            "properties": {
                "dynamic_range": {
                    "type": "string",
                    "enum": ["compressed", "normal", "wide", "HDR"],
                },
                "shadow_depth": {
                    "type": "string",
                    "enum": ["lifted", "medium", "deep", "crushed"],
                },
                "highlight_character": {"type": "string"},
            },
            "required": ["dynamic_range", "shadow_depth", "highlight_character"],
        },
        "atmosphere": {
            "type": "object",
            "properties": {
                "mood": {"type": "string"},
                "emotional_tone": {"type": "string"},
                "genre": {"type": "string"},
            },
            "required": ["mood", "emotional_tone", "genre"],
        },
    },
    "required": [
        "style_tag",
        "color_grading",
        "lighting",
        "texture",
        "composition",
        "contrast",
        "atmosphere",
    ],
}

SYSTEM_PROMPT = (
    "You are an expert visual aesthetics analyst. Analyze images for their "
    "aesthetic DNA — how they feel, not what they contain. Use photography and "
    "cinematography terminology. Return your analysis as structured JSON matching "
    "the provided schema."
)

USER_PROMPT = """Extract the complete aesthetic DNA of this image as JSON with these fields:
- style_tag: 2-4 word aesthetic descriptor
- color_grading: dominant_colors (array of hex codes like #FF5500), palette_type (warm/cool/neutral/mixed), color_temperature, saturation (low/medium/high/vivid)
- lighting: direction, quality (hard/soft/diffused/mixed), contrast_ratio (low/medium/high/extreme), mood
- texture: grain (none/fine/medium/heavy), surface_quality, sharpness (soft/moderate/sharp/crisp)
- composition: technique, depth_layers (flat/shallow/medium/deep), framing
- contrast: dynamic_range (compressed/normal/wide/HDR), shadow_depth (lifted/medium/deep/crushed), highlight_character
- atmosphere: mood, emotional_tone, genre"""


@retry(max_retries=2)
def analyze_image(image_path: str) -> AestheticProfile:
    logger.info("Analyzing image: %s", image_path)
    client = get_together_client()
    data_uri = encode_image(image_path, resize=True)

    try:
        response = client.chat.completions.create(
            model=VISION_MODEL,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": USER_PROMPT},
                        {"type": "image_url", "image_url": {"url": data_uri}},
                    ],
                },
            ],
            response_format={"type": "json_schema", "schema": AESTHETIC_SCHEMA},
        )
    except Exception as e:
        logger.error("Together AI vision call failed: %s", e)
        raise HTTPException(status_code=502, detail=f"Vision API error: {e}")

    if not response.choices or not response.choices[0].message.content:
        logger.error("Vision API returned empty response")
        raise HTTPException(status_code=502, detail="Vision API returned empty response")

    raw = response.choices[0].message.content
    logger.info("Vision analysis complete for %s", image_path)

    try:
        profile = AestheticProfile.model_validate_json(raw)
    except Exception as e:
        logger.error("Failed to parse vision response: %s — raw: %s", e, raw[:500])
        raise HTTPException(status_code=422, detail=f"Could not parse style profile: {e}")

    return profile
