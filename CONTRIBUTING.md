# Contributing

Thanks for your interest in contributing to Style DNA!

## Development Setup

### Backend

```bash
cd aesthetic-style-builder
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # add your Together API key
uvicorn main:app --reload
```

### Frontend

```bash
cd aesthetic_style_dna
flutter pub get
flutter run -d macos  # or: chrome, ios, android
```

## Code Style

- **Python**: Follow PEP 8. Use type hints for function signatures.
- **Dart**: Run `flutter analyze` before submitting. Follow standard Flutter conventions.

## Pull Requests

1. Fork the repo and create a feature branch from `main`
2. Make your changes with clear, descriptive commits
3. Ensure the backend starts without errors and `flutter analyze` passes
4. Open a PR with a description of what changed and why

## Reporting Issues

Open a GitHub issue with:
- What you expected to happen
- What actually happened
- Steps to reproduce
- Environment details (OS, Python/Flutter version)
