import json
import os
import uuid
from datetime import datetime

from agno.workflow import Workflow, WorkflowExecutionInput
from agno.db.sqlite import SqliteDb

from models import AestheticProfile, StyleReference
from utils import logger

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STYLES_FILE = os.path.join(BASE_DIR, "styles.json")
DB_DIR = os.path.join(BASE_DIR, "data")
DB_FILE = os.path.join(DB_DIR, "style_builder.db")

STYLES_PERSIST_FILE = os.path.join(DB_DIR, "style_library.json")

os.makedirs(DB_DIR, exist_ok=True)


def _persist_styles(session_state: dict):
    """Write style library to disk so it survives container restarts."""
    try:
        with open(STYLES_PERSIST_FILE, "w") as f:
            json.dump(session_state.get("style_library", {}), f)
    except Exception as e:
        logger.warning("Could not persist styles: %s", e)


def _migrate_styles_json(session_state: dict):
    """Load styles into session_state: persistent file first, then seed file."""
    if session_state.get("style_library"):
        return
    # Try persistent file first (survives restarts)
    if os.path.exists(STYLES_PERSIST_FILE):
        try:
            with open(STYLES_PERSIST_FILE) as f:
                data = json.load(f)
            if data:
                session_state["style_library"] = data
                logger.info("Loaded %d styles from persistent storage", len(data))
                return
        except Exception as e:
            logger.warning("Could not load persistent styles: %s", e)
    # Fall back to seed file
    if os.path.exists(STYLES_FILE):
        try:
            with open(STYLES_FILE) as f:
                legacy = json.load(f)
            if legacy:
                session_state["style_library"] = legacy
                logger.info("Migrated %d styles from styles.json", len(legacy))
        except Exception as e:
            logger.warning("Could not migrate styles.json: %s", e)


def style_builder_fn(
    workflow: Workflow, execution_input: WorkflowExecutionInput, session_state: dict
):
    """Agno workflow function that orchestrates analyze/create/CRUD via session_state."""
    action = json.loads(execution_input.input)
    action_type = action["type"]

    _migrate_styles_json(session_state)

    if "style_library" not in session_state:
        session_state["style_library"] = {}
    if "total_analyses" not in session_state:
        session_state["total_analyses"] = 0
    if "total_generations" not in session_state:
        session_state["total_generations"] = 0
    if "generation_history" not in session_state:
        session_state["generation_history"] = []

    if action_type == "analyze":
        from analyze import analyze_image

        profile = analyze_image(action["image_path"])
        session_state["total_analyses"] += 1

        # Create and store the style reference
        style_id = uuid.uuid4().hex[:8]
        custom_tag = action.get("custom_tag")
        ref = StyleReference(
            id=style_id,
            style_tag=custom_tag or profile.style_tag,
            profile=profile,
            source_image_path=action.get("image_path"),
            created_at=datetime.now().isoformat(),
        )
        session_state["style_library"][style_id] = ref.model_dump()
        _persist_styles(session_state)
        logger.info("Style '%s' saved with id %s", ref.style_tag, style_id)
        return json.dumps({"ref": ref.model_dump(), "profile": profile.model_dump()})

    elif action_type == "create":
        from create import compose_style_prompt, generate_image

        profiles = [AestheticProfile(**p) for p in action["profiles"]]
        prompt = compose_style_prompt(profiles, action.get("user_prompt"))
        filename = generate_image(
            prompt,
            reference_image_path=action.get("reference_image_path"),
            style_reference_image_paths=action.get("style_source_image_paths"),
            width=action.get("width", 1024),
            height=action.get("height", 1024),
            seed=action.get("seed"),
        )
        session_state["total_generations"] += 1
        session_state["generation_history"].append({
            "filename": filename,
            "prompt": prompt,
            "timestamp": datetime.now().isoformat(),
        })
        return json.dumps({"filename": filename, "prompt_used": prompt})

    elif action_type == "transfer":
        from create import compose_transfer_prompt, generate_transfer_image

        profile = AestheticProfile(**action["profile"])
        prompt = compose_transfer_prompt(profile)
        filename = generate_transfer_image(
            prompt,
            image_path=action["image_path"],
            style_reference_image_path=action.get("style_source_image_path"),
            width=action.get("width", 1024),
            height=action.get("height", 1024),
            seed=action.get("seed"),
        )
        session_state["total_generations"] += 1
        session_state["generation_history"].append({
            "filename": filename,
            "prompt": prompt,
            "timestamp": datetime.now().isoformat(),
            "type": "transfer",
        })
        return json.dumps({"filename": filename, "prompt_used": prompt})

    elif action_type == "list_styles":
        styles = list(session_state["style_library"].values())
        return json.dumps({"styles": styles, "count": len(styles)})

    elif action_type == "get_style":
        style = session_state["style_library"].get(action["style_id"])
        if style is None:
            return json.dumps({"error": "not_found"})
        return json.dumps(style)

    elif action_type == "delete_style":
        lib = session_state["style_library"]
        if action["style_id"] in lib:
            del lib[action["style_id"]]
            _persist_styles(session_state)
            return json.dumps({"deleted": True})
        return json.dumps({"error": "not_found"})

    else:
        return json.dumps({"error": f"Unknown action type: {action_type}"})


style_workflow = Workflow(
    name="Aesthetic Style Builder",
    db=SqliteDb(db_file=DB_FILE),
    steps=style_builder_fn,
    session_state={"style_library": {}, "total_analyses": 0, "total_generations": 0, "generation_history": []},
)
