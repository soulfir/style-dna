import base64
import functools
import logging
import os
import time
from io import BytesIO

from PIL import Image
from together import Together
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("style_builder")

_client = None


def get_together_client() -> Together:
    global _client
    if _client is None:
        api_key = os.getenv("TOGETHER_API_KEY")
        if not api_key:
            raise RuntimeError("TOGETHER_API_KEY environment variable is not set")
        _client = Together(api_key=api_key)
    return _client


def resize_for_vision(image_path: str, max_side: int = 1024) -> bytes:
    """Resize image to max_side on longest dimension for efficient vision API usage."""
    with Image.open(image_path) as img:
        if max(img.size) > max_side:
            img.thumbnail((max_side, max_side), Image.LANCZOS)
        buf = BytesIO()
        fmt = img.format or "PNG"
        if fmt.upper() == "JPEG":
            img.save(buf, format="JPEG", quality=90)
        else:
            img.save(buf, format=fmt)
        return buf.getvalue()


def encode_image(image_path: str, resize: bool = False) -> str:
    ext = image_path.rsplit(".", 1)[-1].lower()
    mime_types = {
        "jpg": "jpeg",
        "jpeg": "jpeg",
        "png": "png",
        "gif": "gif",
        "webp": "webp",
    }
    mime = mime_types.get(ext, "jpeg")

    if resize:
        raw = resize_for_vision(image_path)
        encoded = base64.b64encode(raw).decode("utf-8")
    else:
        with open(image_path, "rb") as f:
            encoded = base64.b64encode(f.read()).decode("utf-8")

    return f"data:image/{mime};base64,{encoded}"


def prepare_reference_images(source_image_paths: list) -> list[str] | None:
    """Validate and encode style source images for use as reference_images.

    Returns None if no valid references found (so the kwarg can be omitted).
    Resizes to 1024px max to save bandwidth since style info is macro-level.
    """
    valid_refs = []
    for path in source_image_paths:
        if path and os.path.exists(path):
            try:
                valid_refs.append(encode_image(path, resize=True))
            except Exception as e:
                logger.warning("Could not encode reference image %s: %s", path, e)
        elif path:
            logger.warning("Reference image not found on disk: %s", path)
    return valid_refs if valid_refs else None


def retry(max_retries: int = 2, base_delay: float = 1.0):
    """Retry decorator with exponential backoff for transient failures."""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            last_exc = None
            for attempt in range(max_retries + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    last_exc = e
                    if attempt < max_retries:
                        delay = base_delay * (2 ** attempt)
                        logger.warning(
                            "Attempt %d/%d for %s failed: %s. Retrying in %.1fs",
                            attempt + 1, max_retries + 1, func.__name__, e, delay,
                        )
                        time.sleep(delay)
                    else:
                        logger.error(
                            "All %d attempts for %s failed: %s",
                            max_retries + 1, func.__name__, e,
                        )
            raise last_exc
        return wrapper
    return decorator
