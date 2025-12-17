# Repository Guidelines

## Project Structure & Module Organization
- `app/main.py`: FastAPI application with the `/health` endpoint; add new routes here and keep shared utilities near their callers unless they are reused.
- `requirements.txt`: Minimal dependency list; prefer stdlib where possible.
- `Dockerfile`: Uvicorn-based image tuned for AWS Fargate; update only when runtime or dependency changes require it.
- `README.md`: Quickstart and AWS notes; keep in sync when workflows change.

## Build, Test, and Development Commands
- Install deps: `pip install -r requirements.txt` (use a virtualenv or `python -m venv .venv && source .venv/bin/activate`).
- Run locally: `uvicorn app.main:app --reload --port 8001`; verify with `curl http://localhost:8001/health`.
- Build image: `docker build -t fastapi-health .`.
- Run image: `docker run -p 8001:8001 fastapi-health`.
- Push to ECR (ECS/EKS Fargate): tag image to `<ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/fastapi-health:latest` and `docker push` after `aws ecr get-login-password`.

## Coding Style & Naming Conventions
- Python: follow PEP 8 with 4-space indents, `snake_case` for functions/vars, `PascalCase` for classes, modules in lowercase, constants in `UPPER_SNAKE`.
- Type hints for public functions and request/response models; keep handlers thin and extract helpers when logic grows.
- Keep endpoints minimal and self-documenting; return JSON objects and align response shapes with health-check pattern.

## Testing Guidelines
- Preferred framework: `pytest`; place files in `tests/` named `test_*.py` to mirror app structure (e.g., `tests/test_health.py`).
- Use `TestClient` from FastAPI/Starlette to exercise routes without running the server; aim to cover the `/health` path and any future business logic.
- Add fixtures for shared setup; keep tests fast and hermetic.

## Commit & Pull Request Guidelines
- Commits: short, imperative subjects ("Add health check", "Update Docker build"); group related changes with concise bodies if rationale is non-obvious.
- PRs: describe intent, list key changes, include commands run (e.g., `uvicorn ...`, `pytest`), and note deployment impact (new ECR tag, infra changes). Link issues when relevant and attach screenshots/logs for failures.

## Security & Configuration Tips
- Do not commit secrets or AWS credentials; use environment variables or local `.env` files excluded from VCS.
- Keep container images minimal; remove unused dependencies before pushing to ECR.
- When adding infra, prefer least-privilege IAM policies and limit exposed ports to the application needs (port 8001 for health/demo flows).
