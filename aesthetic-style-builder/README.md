# aesthetic-style-builder

FastAPI backend for Style DNA. See the [main README](../README.md) for full documentation.

## Quick Start

```bash
cp .env.example .env  # add your Together API key
docker compose up --build
```

Or manually:

```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```
