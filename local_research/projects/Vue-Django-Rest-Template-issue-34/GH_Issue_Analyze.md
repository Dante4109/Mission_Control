VDRF-0034 -- Dockerize Project
Analysis:
Containerize the Vue 3 + Django 5 single-repo project using a single Dockerfile that builds the frontend and runs the backend, while preserving the existing Heroku deployment pipeline unchanged.

**Date:** 2026-07-14
**Author:** rogerjohnmorellizeller@gmail.com
**GH Issue Link:** https://github.com/Dante4109/Vue-Django-Rest-Template/issues/34
**GH Issue Labels:** enhancement, core
**Affected Systems:** Project root (Dockerfile, docker-compose), backend/settings/dev.py (env var consumption), .gitignore, README.md
**Target Surface:** Local developer environment — Docker-based single-command startup

---

## Acceptance Criteria

- Docker image builds successfully with both Python 3.10+ and Node.js installed
- `docker-compose up` starts the container and serves Vue frontend + Django API on port 8000
- Django connects to a PostgreSQL database running on the host machine (host.docker.internal / 172.17.0.1)
- Vue frontend assets are served correctly and API endpoints are accessible from the container
- Non-Docker development (npm run dev + python manage.py runserver) works identically to the pre-Docker state
- No modifications to Procfile, runtime.txt, requirements.txt, or Heroku config
- All Docker-specific files are documented in README.md

> Unclear/implicit items: Whether `collectstatic` must run inside the Docker build (existing setup omits it since Vite output lands directly in STATIC_ROOT); whether hot-reload via volume mounts is required for the frontend (Vite frontend is pre-built at image build time, so volume mounts affect only backend Python files).

---

## Overview

Add a single-container Docker setup (Dockerfile + docker-compose.yml + .env.docker template + .dockerignore) that builds the Vue 3 frontend via Vite and serves it through Django/WhiteNoise, connecting to an external host PostgreSQL, with zero changes to the existing Heroku deployment files.

---

## Scope

**In Scope:**
- Dockerfile at project root: Python 3.10 base + Node.js install + Vite build + gunicorn startup
- docker-compose.yml: web service, env_file, port 8000, Linux extra_hosts for host-gateway
- .dockerignore: exclude node_modules, venv, dist, __pycache__, .env files, mediafiles_cdn
- .env.docker: template (committed) documenting all required environment variables
- .gitignore: add .env.docker to secrets exclusion (committed .env.docker.template only)
- README.md: Docker setup section with startup instructions and troubleshooting
- Verification that backend/settings/dev.py env var consumption is compatible with Docker (no file changes expected)

**Out of Scope:**
- Modifying Procfile, runtime.txt, requirements.txt, or any Heroku configuration
- Containerizing PostgreSQL (external host DB is the stated requirement)
- CI/CD pipeline changes
- Production Docker deployment to Heroku
- Frontend hot-reload inside the container (frontend is compiled at image build time)

---

## Requirements

- Dockerfile must install Python and Node.js in one image; use a Python base and layer Node.js via NodeSource or nvm
- `npm ci && npm run build` must execute during image build so dist/ is present before Django starts
- gunicorn must be invoked as the CMD: `gunicorn backend.wsgi --log-file -` (mirrors Procfile)
- DJANGO_SETTINGS_MODULE must be set to `backend.settings.dev` in the container environment
- ALLOWED_HOSTS env var must be a valid JSON array string because settings.py does `json.loads(os.getenv("ALLOWED_HOSTS"))`
- ENV_TYPE must be set to `DEV` so settings.py uses the individual DB_* vars instead of the Heroku DATABASE_URL path
- DB_HOST must default to `host.docker.internal` (Windows/Mac) with Linux workaround documented
- docker-compose.yml must add `extra_hosts: ["host.docker.internal:host-gateway"]` for Linux compatibility
- .env.docker committed to repo must contain ONLY placeholder values (no real secrets)
- .gitignore must exclude any .env.docker file that carries real secret values

---

## Dependencies & Contracts

- `backend/settings/dev.py` — reads all config from environment variables via `os.getenv()`; `load_dotenv()` loads `backend/.env` but does NOT override pre-existing env vars, so Docker-injected vars take precedence automatically — no settings file changes needed
- `backend/wsgi.py` — hardcodes `DJANGO_SETTINGS_MODULE=backend.settings.dev`; container must match this or override via environment
- `vite.config.mjs` — builds to `dist/` (project root); Django TEMPLATES DIRS includes `"dist"` (relative to BASE_DIR = project root = /app in container)
- `backend/settings/dev.py` STATIC_ROOT — set to `BASE_DIR/dist/static`; Vite outputs assets to `dist/static/` matching this path, so WhiteNoise serves them without `collectstatic`
- `package.json` scripts — `build` runs `vite build`; `npm ci` is preferred over `npm install` for reproducible builds
- `requirements.txt` — includes gunicorn, psycopg2-binary, whitenoise; no additional packages needed for Docker
- `django-todo-app` at `C:\projects\AppDev\django-todo-app` — reference Dockerfile and docker-compose.yml patterns (Python base, simple COPY + pip install pattern)

---

## Risks & Constraints

- ALLOWED_HOSTS JSON parse: if the env var is not a valid JSON array string (e.g., missing brackets), Django will throw a startup error. Document exact format in .env.docker template.
- WhiteNoise STATICFILES_DIRS conflict: `backend/settings/dev.py` STATICFILES_DIRS points into STATIC_ROOT subdirectories. Running `collectstatic` would fail because source and destination overlap. Avoid calling `collectstatic` in the Docker entrypoint; WhiteNoise in `MIDDLEWARE` serves files directly from STATIC_ROOT.
- WSGI_APPLICATION hardcoded as `backend.wsgi.application`; manage.py at project root points Django to the correct wsgi.py — no path issues inside the container as long as WORKDIR=/app.
- node_modules size: if not properly excluded in .dockerignore, the build context will be very large. `node_modules` must be in .dockerignore.
- `dist/` excluded from .gitignore (`/dist`) but must be rebuilt inside the container — confirm .dockerignore also excludes `/dist` so local developer dist/ doesn't bleed into the image.
- Heroku: the Dockerfile/docker-compose.yml files are inert on Heroku because Heroku ignores them when a Procfile is present (Heroku's container stack requires explicit opt-in). No risk to existing Heroku deployment.
- Email settings (EMAIL_BACKEND, EMAIL_HOST, etc.) are read from env; .env.docker template must include them as empty placeholders to prevent Django errors at startup.

---

## Open Questions

- Should the .env.docker file be committed as a template with placeholder values, or should a separate .env.docker.template be committed and .env.docker gitignored?
- Is frontend hot-reload inside the container desired? If so, a separate Vite dev server container would be needed (currently out of scope per issue).
- Should `python manage.py migrate` run automatically on container startup, or only manually? (Procfile runs it as a Heroku release step, not in the web process.)
- What Python version should the Docker base image pin? requirements.txt doesn't specify; Django 5.1.1 requires Python 3.10+. Python 3.12 matches the django-todo-app reference pattern.

---

## Implementation Phases

### Discovery / Design

- Confirm that Django's `load_dotenv` does not override Docker-injected environment variables (verified: python-dotenv default is override=False)
- Confirm that dist/ build output path aligns between Vite config (outDir: 'dist') and Django TEMPLATES DIRS ("dist") and STATIC_ROOT (BASE_DIR/dist/static)
- Identify all environment variables consumed by backend/settings/dev.py that must be present in .env.docker template

### Build

- Create Dockerfile (Python 3.12 base, NodeSource Node.js install, npm ci + npm run build, pip install, WORKDIR /app, EXPOSE 8000, CMD gunicorn)
- Create .dockerignore (node_modules, venv, .venv, dist, __pycache__, .pytest_cache, .env*, mediafiles_cdn, .coverage)
- Create docker-compose.yml (web service, build: ., ports 8000:8000, env_file: .env.docker, extra_hosts host.docker.internal:host-gateway)
- Create .env.docker template with all required vars and placeholder values
- Update .gitignore to add .env.docker exclusion rule (if committing real values) or document that template file carries only placeholders
- Update README.md with Docker setup section

### Validate

- Run `docker build -t vdrf:latest .` and confirm clean exit
- Run `docker-compose up` and confirm server starts on port 8000
- Access http://localhost:8000 and confirm Vue SPA renders
- Access http://localhost:8000/api/auth/obtain_token/ and confirm API responds
- Confirm external PostgreSQL connection succeeds (run `docker exec <container> python manage.py dbshell`)
- Run project without Docker (npm run dev + python manage.py runserver) and confirm unchanged behavior
- Verify Heroku deployment unaffected by pushing to staging (or confirming Procfile/runtime.txt untouched)

### Rollout

- Commit Dockerfile, docker-compose.yml, .dockerignore, .env.docker (template only), updated .gitignore, updated README.md
- No source code changes; no Heroku pipeline changes

---

## Testing Strategy

**Unit Tests:** No new unit tests required — this is infrastructure-only; existing pytest suite should pass inside the container  
**Integration Tests:** Manual verification of Docker build + startup + API response + DB connection  
**E2E Tests:** Navigate SPA, authenticate, confirm Vuex/JWT flow works inside container  
**Migration/Backfill:** No migrations introduced; verify existing migrations run cleanly via `docker exec <container> python manage.py migrate`  
**Observability:** Container logs via `docker-compose logs -f`; Django prints DB_URL / DEBUG status at startup from existing print() statements in dev.py

---

## Logging, Monitoring & Rollback

- Django settings/dev.py already prints `DEBUG Mode` and `Found DB_URL` on startup — visible in `docker-compose logs`
- gunicorn `--log-file -` routes logs to stdout, captured by docker-compose
- Rollback: Docker files are additive only; remove Dockerfile, docker-compose.yml, .env.docker to revert — no source code changes to undo

---

## Proposed Subtasks

- [ ] Create Dockerfile at project root using Python 3.12 base, install Node.js via NodeSource, run `npm ci && npm run build`, install Python deps, set WORKDIR /app, EXPOSE 8000, CMD gunicorn backend.wsgi --log-file -
- [ ] Create .dockerignore at project root excluding node_modules, venv, .venv, dist, __pycache__, .pytest_cache, .env*, mediafiles_cdn, .coverage, cypress
- [ ] Create docker-compose.yml with a web service that builds from Dockerfile, maps port 8000:8000, uses env_file .env.docker, and adds extra_hosts entry for host.docker.internal on Linux
- [ ] Create .env.docker template committed with placeholder values documenting DJANGO_SETTINGS_MODULE, ENV_TYPE, DJANGO_SECRET_KEY, DEBUG, ALLOWED_HOSTS (JSON array), DB_NAME, DB_HOST, DB_USER, DB_PASSWORD, DB_PORT, AWS_S3, and all EMAIL_* vars
- [ ] Update .gitignore to exclude .env.docker from version control if it will carry real secret values; add comment documenting .env.docker.template as the committed reference
- [ ] Verify backend/settings/dev.py env var consumption is Docker-compatible without code changes (load_dotenv does not override Docker-set vars; ALLOWED_HOSTS must be a JSON array string)
- [ ] Update README.md with a Docker Setup section covering prerequisites, build command, docker-compose up, .env.docker configuration, and external DB connection instructions for Windows/Mac/Linux
- [ ] Test docker build -t vdrf:latest . completes without error
- [ ] Test docker-compose up starts correctly and Vue SPA is served at http://localhost:8000
- [ ] Test API endpoints accessible at http://localhost:8000/api/ and external PostgreSQL connection works
- [ ] Verify non-Docker development is unchanged (npm run dev + python manage.py runserver still works)
- [ ] Verify Heroku deployment is unaffected (Procfile, runtime.txt, requirements.txt unchanged)

---

## Existing Artifacts

- `C:\projects\AppDev\VDRF_Template` — local clone of Vue-Django-Rest-Template (the target repo)
- `C:\projects\AppDev\django-todo-app` — reference Docker implementation (Dockerfile, docker-compose.yml, .dockerignore patterns)
- `C:\projects\AppDev\VDRF_Template\Procfile` — `release: python manage.py migrate` + `web: gunicorn backend.wsgi --log-file -`
- `C:\projects\AppDev\VDRF_Template\backend\settings\dev.py` — all env var consumption; DB config branching on ENV_TYPE
- `C:\projects\AppDev\VDRF_Template\vite.config.mjs` — builds to dist/ at project root; static assets under dist/static/
- `C:\projects\AppDev\VDRF_Template\requirements.txt` — includes gunicorn, psycopg2-binary, whitenoise (no Docker-specific additions needed)
