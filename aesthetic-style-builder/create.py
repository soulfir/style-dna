import base64
import os
from datetime import datetime
from typing import Optional, List

from fastapi import HTTPException

from models import AestheticProfile
from utils import get_together_client, encode_image, prepare_reference_images, retry, logger

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(BASE_DIR, "output")

CHAT_MODEL = os.getenv("CHAT_MODEL", "meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8")
IMAGE_MODEL = os.getenv("IMAGE_MODEL", "black-forest-labs/FLUX.2-pro")


@retry(max_retries=2)
def compose_style_prompt(
    profiles: List[AestheticProfile], user_prompt: Optional[str] = None
) -> str:
    logger.info("Composing style prompt from %d profile(s)", len(profiles))
    client = get_together_client()

    profiles_text = ""
    for i, p in enumerate(profiles, 1):
        profiles_text += f"""
Style {i}: "{p.style_tag}"
  Colors: {', '.join(p.color_grading.dominant_colors)} ({p.color_grading.palette_type}, {p.color_grading.saturation} saturation, {p.color_grading.color_temperature})
  Lighting: {p.lighting.direction}, {p.lighting.quality} quality, {p.lighting.contrast_ratio} contrast, {p.lighting.mood}
  Texture: {p.texture.grain} grain, {p.texture.surface_quality}, {p.texture.sharpness} sharpness
  Composition: {p.composition.technique}, {p.composition.depth_layers} depth, {p.composition.framing}
  Contrast: {p.contrast.dynamic_range} range, {p.contrast.shadow_depth} shadows, {p.contrast.highlight_character}
  Atmosphere: {p.atmosphere.mood}, {p.atmosphere.emotional_tone}, {p.atmosphere.genre}
"""

    scene_instruction = ""
    if user_prompt:
        scene_instruction = f"\n\nThe scene/subject to depict: {user_prompt}"

    system_msg = (
        "You are an expert at composing FLUX image generation prompts from aesthetic profiles. "
        "Output a single prompt under 200 words using this structure: "
        "[subject], [art style/medium], [color palette with hex codes], "
        "[lighting setup], [texture/surface], [mood/atmosphere], [composition/framing]. "
        "Use specific terminology: named lighting setups (Rembrandt, butterfly, split), "
        "exact color hex codes, medium descriptions (oil on canvas, graphite on paper). "
        "If styles conflict, prioritize the first listed style. "
        "Style reference images may be provided as numbered references for visual style ONLY. "
        "Include in your prompt: 'From the reference images extract ONLY the color grading, lighting style, "
        "texture, and atmosphere. NEVER copy, reproduce, or include any objects, subjects, people, animals, "
        "or scene elements from the reference images.' "
        "Output ONLY the prompt text, no explanation or preamble."
    )

    user_msg = f"""Compose a detailed image generation prompt that captures these aesthetic qualities:
{profiles_text}{scene_instruction}

The prompt should describe the visual style (colors, lighting, texture, mood, composition) in natural language suitable for FLUX image generation. Be specific and use precise visual terminology."""

    try:
        response = client.chat.completions.create(
            model=CHAT_MODEL,
            messages=[
                {"role": "system", "content": system_msg},
                {"role": "user", "content": user_msg},
            ],
        )
    except Exception as e:
        logger.error("Together AI chat call failed: %s", e)
        raise HTTPException(status_code=502, detail=f"Prompt composition API error: {e}")

    if not response.choices or not response.choices[0].message.content:
        logger.error("Chat API returned empty response")
        raise HTTPException(status_code=502, detail="Prompt composition returned empty response")

    prompt = response.choices[0].message.content.strip()
    logger.info("Composed prompt: %s", prompt[:100])
    return prompt


@retry(max_retries=2)
def generate_image(
    prompt: str,
    reference_image_path: Optional[str] = None,
    style_reference_image_paths: Optional[List[str]] = None,
    width: int = 1024,
    height: int = 1024,
    seed: Optional[int] = None,
    negative_prompt: Optional[str] = None,
) -> str:
    logger.info("Generating image: %dx%d, ref=%s", width, height, reference_image_path)
    client = get_together_client()

    kwargs = {
        "model": IMAGE_MODEL,
        "prompt": prompt,
        "width": width,
        "height": height,
        "response_format": "b64_json",
    }

    all_refs = []
    if reference_image_path:
        all_refs.append(encode_image(reference_image_path))
    if style_reference_image_paths:
        style_refs = prepare_reference_images(style_reference_image_paths)
        if style_refs:
            all_refs.extend(style_refs)
    if all_refs:
        kwargs["reference_images"] = all_refs

    if seed is not None:
        kwargs["seed"] = seed

    try:
        response = client.images.generate(**kwargs)
    except Exception as e:
        logger.error("Together AI image generation failed: %s", e)
        raise HTTPException(status_code=502, detail=f"Image generation API error: {e}")

    if not response.data or not response.data[0].b64_json:
        logger.error("Image API returned empty data")
        raise HTTPException(status_code=502, detail="Image generation returned no data")

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"generated_{timestamp}.png"
    filepath = os.path.join(OUTPUT_DIR, filename)

    image_data = base64.b64decode(response.data[0].b64_json)
    with open(filepath, "wb") as f:
        f.write(image_data)

    logger.info("Image saved: %s", filename)
    return filename


@retry(max_retries=2)
def compose_transfer_prompt(profile: AestheticProfile) -> str:
    """Compose a transformation instruction for FLUX Kontext image-to-image style transfer."""
    logger.info("Composing transfer prompt for style '%s'", profile.style_tag)
    client = get_together_client()

    profile_text = f"""Target style: "{profile.style_tag}"
  Colors: {', '.join(profile.color_grading.dominant_colors)} ({profile.color_grading.palette_type}, {profile.color_grading.saturation} saturation, {profile.color_grading.color_temperature})
  Lighting: {profile.lighting.direction}, {profile.lighting.quality} quality, {profile.lighting.contrast_ratio} contrast, {profile.lighting.mood}
  Texture: {profile.texture.grain} grain, {profile.texture.surface_quality}, {profile.texture.sharpness} sharpness
  Composition: {profile.composition.technique}, {profile.composition.depth_layers} depth, {profile.composition.framing}
  Contrast: {profile.contrast.dynamic_range} range, {profile.contrast.shadow_depth} shadows, {profile.contrast.highlight_character}
  Atmosphere: {profile.atmosphere.mood}, {profile.atmosphere.emotional_tone}, {profile.atmosphere.genre}"""

    system_msg = (
        "You are an expert at composing MAXIMALLY AGGRESSIVE FLUX Kontext style transfer instructions. "
        "Your output must be a SINGLE, FORCEFUL transformation instruction under 150 words. "
        "Rules: "
        "1. START with a STRONG action: 'COMPLETELY RESTYLE AS', 'FULLY TRANSFORM INTO', 'CONVERT ENTIRELY TO'. "
        "2. Use MAXIMUM intensity descriptors: vivid, extreme, saturated, bold, intense, pronounced, exaggerated. "
        "3. For EVERY visual element, describe the EXTREME expression: "
        "   - Colors: fully saturated hex codes (#FF0000 not #FF8080), bold and dominant "
        "   - Lighting: dramatic setups, strong contrast, hard shadows or extreme softness "
        "   - Texture: prominent, visible, exaggerated (thick brushstrokes, heavy cross-hatching, bold outlines) "
        "   - Mood: amplify emotional intensity to maximum "
        "4. Explicitly demand COMPLETE REPLACEMENT of the original photographic style. "
        "5. End with: 'Apply this style with MAXIMUM STRENGTH while preserving the original subject and composition.' "
        "6. Do NOT describe image content — only describe the target visual style. "
        "7. Output ONLY the instruction, no explanation. "
        "8. A style reference image (image 2) will be provided alongside the source image (image 1). "
        "You MUST include in the instruction: 'From image 2 extract ONLY the color grading, lighting, and texture. "
        "NEVER copy any objects, subjects, people, animals, or scene elements from image 2. "
        "The output must contain ONLY the content from image 1.'"
    )

    user_msg = f"""Compose a style transfer instruction for this aesthetic profile:
{profile_text}

The instruction should tell FLUX Kontext how to restyle the input image to match this aesthetic."""

    try:
        response = client.chat.completions.create(
            model=CHAT_MODEL,
            messages=[
                {"role": "system", "content": system_msg},
                {"role": "user", "content": user_msg},
            ],
        )
    except Exception as e:
        logger.error("Together AI chat call failed: %s", e)
        raise HTTPException(status_code=502, detail=f"Transfer prompt composition API error: {e}")

    if not response.choices or not response.choices[0].message.content:
        logger.error("Chat API returned empty response for transfer prompt")
        raise HTTPException(status_code=502, detail="Transfer prompt composition returned empty response")

    prompt = response.choices[0].message.content.strip()
    logger.info("Composed transfer prompt: %s", prompt[:100])
    return prompt


@retry(max_retries=2)
def generate_transfer_image_raw(
    prompt: str,
    image_path: str,
    style_reference_image_path: Optional[str] = None,
    width: int = 1024,
    height: int = 1024,
    seed: Optional[int] = None,
) -> bytes:
    """Generate a style-transferred image and return raw bytes. No HTTPException (safe for background threads)."""
    logger.info("Generating transfer image (raw): %dx%d, source=%s", width, height, image_path)
    client = get_together_client()

    ref_images = [encode_image(image_path)]
    if style_reference_image_path:
        style_refs = prepare_reference_images([style_reference_image_path])
        if style_refs:
            ref_images.extend(style_refs)

    # When style ref is present, tell FLUX.2 to use image 2 for style
    final_prompt = prompt
    if len(ref_images) > 1:
        final_prompt += (
            " Apply this transformation to image 1 ONLY."
            " From image 2 extract ONLY the color grading, lighting style, texture, and atmosphere."
            " NEVER copy, reproduce, or include any objects, subjects, people, animals, or scene elements from image 2."
            " The output must contain ONLY the subject and scene from image 1, restyled with the visual aesthetic of image 2."
        )

    kwargs = {
        "model": IMAGE_MODEL,
        "prompt": final_prompt,
        "width": width,
        "height": height,
        "reference_images": ref_images,
        "response_format": "b64_json",
    }

    if seed is not None:
        kwargs["seed"] = seed

    response = client.images.generate(**kwargs)

    if not response.data or not response.data[0].b64_json:
        raise RuntimeError("Transfer image generation returned no data")

    return base64.b64decode(response.data[0].b64_json)


@retry(max_retries=2)
def generate_transfer_image(
    prompt: str,
    image_path: str,
    style_reference_image_path: Optional[str] = None,
    width: int = 1024,
    height: int = 1024,
    seed: Optional[int] = None,
) -> str:
    """Generate a style-transferred image using FLUX Kontext image-to-image."""
    logger.info("Generating transfer image: %dx%d, source=%s", width, height, image_path)
    client = get_together_client()

    ref_images = [encode_image(image_path)]
    if style_reference_image_path:
        style_refs = prepare_reference_images([style_reference_image_path])
        if style_refs:
            ref_images.extend(style_refs)

    # When style ref is present, tell FLUX.2 to use image 2 for style
    final_prompt = prompt
    if len(ref_images) > 1:
        final_prompt += (
            " Apply this transformation to image 1 ONLY."
            " From image 2 extract ONLY the color grading, lighting style, texture, and atmosphere."
            " NEVER copy, reproduce, or include any objects, subjects, people, animals, or scene elements from image 2."
            " The output must contain ONLY the subject and scene from image 1, restyled with the visual aesthetic of image 2."
        )

    kwargs = {
        "model": IMAGE_MODEL,
        "prompt": final_prompt,
        "width": width,
        "height": height,
        "reference_images": ref_images,
        "response_format": "b64_json",
    }

    if seed is not None:
        kwargs["seed"] = seed

    try:
        response = client.images.generate(**kwargs)
    except Exception as e:
        logger.error("Together AI transfer image generation failed: %s", e)
        raise HTTPException(status_code=502, detail=f"Transfer image generation API error: {e}")

    if not response.data or not response.data[0].b64_json:
        logger.error("Transfer image API returned empty data")
        raise HTTPException(status_code=502, detail="Transfer image generation returned no data")

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"transfer_{timestamp}.png"
    filepath = os.path.join(OUTPUT_DIR, filename)

    image_data = base64.b64decode(response.data[0].b64_json)
    with open(filepath, "wb") as f:
        f.write(image_data)

    logger.info("Transfer image saved: %s", filename)
    return filename
