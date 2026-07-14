# Vue-Django-Rest-Template-issue-34 — Implementation Plan: Dockerize Project

**Date:** 2026-07-14
**Branch:** VDRF_Dockerize_34
**GH:** https://github.com/Dante4109/Vue-Django-Rest-Template/issues/34

## Overview

This issue adds a single-container Docker setup to the VDRF project so that developers can start the full stack with one `docker-compose up` command. A single Dockerfile installs Python 3.12 and Node.js, compiles the Vue 3 frontend via Vite into `dist/`, installs Python dependencies, and starts Django via gunicorn — exactly mirroring the Procfile web process. WhiteNoise serves the compiled static assets directly from `dist/static/` without a collectstatic step. The container connects to an external PostgreSQL instance on the host machine using `host.docker.internal`. No existing files are modified except `.gitignore` and `README.md`; all Docker infrastructure files are additive. The Heroku pipeline (Procfile, runtime.txt, requirements.txt) is untouched.

---

## Critical Pre-Implementation Notes

1. `package-lock.json` is listed in `.gitignore` (line 23). A fresh clone will not contain a lock file. **`npm ci` requires a lock file and will fail.** The Dockerfile must use `npm install` instead.
2. `requirements.txt` contains both `psycopg2==2.9.9` and `psycopg2-binary==2.9.9`. The non-binary variant requires `libpq-dev` and `gcc` to compile inside the container. Add an apt-get install step for these before pip install.

---

## Subtasks

### Subtask 1: Create Dockerfile

**AC Mapping:** Scenario 1 (Docker Build and Startup) — image builds with Python 3.12 and Node.js; npm run build compiles Vue assets into dist/; gunicorn starts Django on port 8000.

**Files to change:**

- `Dockerfile` (NEW at C:\projects\AppDev\VDRF_Template\Dockerfile) — single-stage build: Python 3.12 base + Node.js 20 LTS via NodeSource + Vite build + pip install + gunicorn CMD

**Steps:**

1. Use `FROM python:3.12` as the base image. Matches the reference django-todo-app pattern and satisfies Django 5.1.1's Python 3.10+ requirement.
2. Install system deps with apt-get: curl (for NodeSource script), libpq-dev and gcc (required by the non-binary psycopg2 package in requirements.txt).
3. Install Node.js 20 LTS via NodeSource setup script. This gives both node and npm in the same image layer without a multi-stage build.
4. Set `WORKDIR /app`.
5. Copy `package.json` only (NOT package-lock.json — it is gitignored and absent from fresh clones). Run `npm install` (not npm ci). This layer is cached as long as package.json does not change.
6. Copy frontend source files required by Vite: `src/`, `index.html`, `vite.config.mjs`, `.browserslistrc`, `.eslintrc.js`, and `public/` if present. Run `npm run build` (maps to `vite build`). Vite writes output to /app/dist/; JS assets at /app/dist/static/js/, CSS at /app/dist/static/css/ — matching Django STATIC_ROOT = BASE_DIR / "dist" / "static" (dev.py line 189).
7. Copy `requirements.txt` and run pip install with --no-cache-dir flag. Installs gunicorn 23.0.0, psycopg2-binary 2.9.9, whitenoise 6.7.0, and all other dependencies.
8. Copy remaining project files with `COPY . .`. Placed last to maximize Docker layer cache reuse — changing source files does not invalidate the npm or pip layers.
9. Add `EXPOSE 8000`.
10. Set CMD to `["gunicorn", "backend.wsgi", "--log-file", "-"]` to mirror the Procfile web: process exactly. backend/wsgi.py line 13 calls os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings.dev"), so the settings module resolves correctly.
11. Do NOT add a collectstatic step. STATICFILES_DIRS in dev.py lines 190-195 points into subdirectories of STATIC_ROOT; collectstatic fails when source and destination overlap. WhiteNoiseMiddleware in MIDDLEWARE (dev.py line 72) serves files from STATIC_ROOT directly.

**Testing:**

- `docker build -t vdrf:latest .` exits with code 0.
- `docker run --rm vdrf:latest ls /app/dist` shows index.html and static/ directory.
- `docker inspect vdrf:latest --format='{{.Config.Cmd}}'` returns [gunicorn backend.wsgi --log-file -].

---

### Subtask 2: Create .dockerignore

**AC Mapping:** Scenario 1 (build context size) — prevents local artifacts from entering the image; keeps build context small and fast.

**Files to change:**

- `.dockerignore` (NEW at C:\projects\AppDev\VDRF_Template\.dockerignore) — excludes large/irrelevant directories from the Docker build context

**Steps:**

1. Exclude `node_modules` — prevents local node_modules/ (potentially hundreds of MB) from being sent to the Docker daemon. The Dockerfile rebuilds it inside the container via npm install.
2. Exclude `venv` and `.venv` — Python virtual environments; not needed in the container.
3. Exclude `dist` — any locally compiled Vite output must not bleed into the image. Vite rebuilds dist/ from source inside the container. Without this exclusion, stale local dist/ would shadow the container-built output.
4. Exclude `__pycache__`, `.pytest_cache` — compiled Python bytecode and test cache artifacts.
5. Exclude `.env*` — prevents any .env, .env_prod, .env_other, .env.docker file with real secrets from being baked into an image layer. Env vars are injected at runtime via docker-compose env_file.
6. Exclude `mediafiles_cdn` — user-uploaded media files; large and irrelevant to the build.
7. Exclude `.coverage`, `htmlcov` — pytest coverage artifacts.
8. Exclude `cypress` — end-to-end test directory.
9. Exclude `.git` — version history not needed in the image.

**Testing:**

- Build context size shown by docker build should be under 10 MB.
- `docker run --rm vdrf:latest ls /app` must NOT show node_modules, venv, or mediafiles_cdn.
- `docker run --rm vdrf:latest ls /app/dist` shows only the container-built Vite output.

---

### Subtask 3: Create docker-compose.yml

**AC Mapping:** Scenario 2 (Container Execution) — docker-compose up starts container on port 8000; Scenario 3 (External DB) — extra_hosts enables Linux host DB resolution.

**Files to change:**

- `docker-compose.yml` (NEW at C:\projects\AppDev\VDRF_Template\docker-compose.yml) — single web service; no database container

**Steps:**

1. Omit the version: key — deprecated in Compose v2+.
2. Define a single service `web:` under services: (no database service; PostgreSQL runs on the host).
3. Set `build: .` to build from the Dockerfile at the project root.
4. Set `container_name: vdrf-web` for predictable naming in docker exec and docker logs commands.
5. Set `ports: ["8000:8000"]` to expose Django/gunicorn on the host at http://localhost:8000.
6. Set `env_file: .env.docker` to load all environment variables from the template file at container startup. Avoids baking secrets into the image or compose file.
7. Add `extra_hosts: ["host.docker.internal:host-gateway"]`. On Linux, this maps host.docker.internal to the host gateway IP, enabling DB_HOST=host.docker.internal to resolve. On Windows and Mac, Docker Desktop provides this mapping natively; the entry is harmless on those platforms.
8. Do NOT add a volumes mount for ./dist:/app/dist. Vite builds dist/ inside the image at build time; a host volume mount would shadow the built dist/ with empty or stale local files, breaking static asset serving.
9. Optionally include a commented-out backend volume for Django hot-reload without full image rebuilds. Leave commented out by default.

**Testing:**

- `docker-compose config` validates YAML with no errors.
- `docker-compose up` with a valid .env.docker starts the container.
- `curl http://localhost:8000` returns an HTTP response.

---

### Subtask 4: Create .env.docker Template

**AC Mapping:** All scenarios — documents every required environment variable with safe placeholder values; prevents cryptic startup errors.

**Files to change:**

- `.env.docker` (NEW at C:\projects\AppDev\VDRF_Template\.env.docker) — committed template with placeholder values only; zero real secrets

**Steps:**

1. Add header comment explaining this is a template and real values must not be committed.
2. `DJANGO_SETTINGS_MODULE=backend.settings.dev` — explicit for clarity even though wsgi.py line 13 sets it via setdefault.
3. `ENV_TYPE=DEV` — activates the DB_* vars path in dev.py line 131. Without this, Django falls into the Heroku DATABASE_URL branch and fails.
4. `DJANGO_SECRET_KEY=your-secret-key-change-me` — read by dev.py line 30.
5. `DEBUG=True` — read by dev.py line 33. String "True" is truthy; Django uses it as-is.
6. `ALLOWED_HOSTS=["localhost","127.0.0.1"]` — CRITICAL: dev.py line 36 does json.loads(os.getenv("ALLOWED_HOSTS")). Must be a valid JSON array string including square brackets. Any other format raises json.JSONDecodeError and crashes Django at startup. Add inline comment documenting this constraint.
7. Database vars: DB_NAME=your_db_name, DB_HOST=host.docker.internal, DB_USER=your_db_user, DB_PASSWORD=your_db_password, DB_PORT=5432. Add comment: Linux users must change DB_HOST to 172.17.0.1 or use: ip route show default | awk '/default/ {print }'
8. `AWS_S3=False` — dev.py line 197 checks if os.getenv("AWS_S3") == "True". String "False" skips the S3 block; local media storage uses mediafiles_cdn/.
9. Email vars: EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend, EMAIL_HOST=, EMAIL_PORT=, EMAIL_HOST_USER=, EMAIL_HOST_PASSWORD=, EMAIL_USE_TLS=. Console backend prints emails to stdout (visible in docker-compose logs) without requiring SMTP. All six vars read unconditionally in dev.py lines 227-232.

**Testing:**

- Cross-reference every os.getenv() call in backend/settings/dev.py against this template — no call should be missing a corresponding entry.
- docker-compose up with real DB credentials in .env.docker starts Django without KeyError, json.JSONDecodeError, or ImproperlyConfigured.

---

### Subtask 5: Update .gitignore

**AC Mapping:** All scenarios (security) — developer-filled .env.docker with real credentials is never committed to version control.

**Files to change:**

- `.gitignore` (MODIFY at C:\projects\AppDev\VDRF_Template\.gitignore) — add exclusion rule after line 20 (end of # local env files section)

**Steps:**

1. Open .gitignore. The # local env files section at lines 12-20 already excludes .env, .env_prod, .env_prod_heroku, .env_old, .env_other.
2. Choose a commit strategy (two options):
   - Option A (recommended): Commit .env.docker as the placeholder template (safe values only). Add .env.docker.local to .gitignore. Developers copy to .env.docker.local, fill in real values, and update docker-compose env_file reference.
   - Option B: Commit .env.docker.template as the placeholder. Add .env.docker to .gitignore. Developers run cp .env.docker.template .env.docker. docker-compose env_file references .env.docker by default.
3. Add the chosen exclusion rule with an explanatory comment after line 20 in the # local env files section.
4. Do not modify any other section of .gitignore.

**Testing:**

- git check-ignore -v <chosen-file> confirms the gitignore rule fires.
- git status after filling in real values confirms the real-secrets file does not appear as staged.
- The placeholder template file IS tracked: git ls-files .env.docker (Option A) or git ls-files .env.docker.template (Option B) returns the filename.

---

### Subtask 6: Verify backend/settings/dev.py Docker Compatibility

**AC Mapping:** Scenario 3 (External DB), Scenario 5 (Non-Docker unchanged) — read-only verification; no code changes expected or needed.

**Files to change:**

- None — read-only verification subtask.

**Steps:**

1. Confirm load_dotenv at dev.py line 24 loads backend/.env with override=False (python-dotenv default). Docker-injected env vars set before the Python process starts take precedence over backend/.env values. No settings file changes needed.
2. Confirm ALLOWED_HOSTS = json.loads(os.getenv("ALLOWED_HOSTS")) at dev.py line 36 requires a JSON array string. Verify .env.docker sets ALLOWED_HOSTS=["localhost","127.0.0.1"].
3. Confirm the ENV_TYPE == "DEV" branch at dev.py line 131 activates DB_* vars. The else branch calls dj_database_url.config(ssl_require=True) — without DATABASE_URL this raises ConfigurationError. Confirm .env.docker does NOT set DATABASE_URL when ENV_TYPE=DEV.
4. Confirm STATIC_ROOT = os.path.join(BASE_DIR, "dist", "static") at dev.py line 189 and TEMPLATES DIRS: ["dist", "backend/users"] at dev.py line 109. Inside the container BASE_DIR = /app, so STATIC_ROOT = /app/dist/static. Vite's build.outDir: 'dist' (vite.config.mjs line 73) and assetFileNames routes (lines 80-99) output JS to dist/static/js/, CSS to dist/static/css/ — these paths align exactly.
5. Confirm STATICFILES_DIRS at dev.py lines 190-195 references STATIC_ROOT subdirectories. Do NOT call collectstatic in the Docker entrypoint — source/destination overlap causes Django CommandError.
6. Confirm all six EMAIL_* vars at dev.py lines 227-232 use os.getenv() with no fallback — None is acceptable when EMAIL_BACKEND is console.EmailBackend.

**Testing:**

- No code execution required. Verification complete when the developer confirms each point against dev.py.
- Optional post-startup check: docker exec vdrf-web python -c "import os; print(os.environ.get('ENV_TYPE'))" should print DEV.

---

### Subtask 7: Update README.md

**AC Mapping:** All scenarios (documentation) — developers can follow step-by-step instructions to build and run the Docker environment from a fresh clone.

**Files to change:**

- `README.md` (MODIFY at C:\projects\AppDev\VDRF_Template\README.md) — append ## Docker Setup section; do not remove or alter existing content

**Steps:**

1. Do not remove or modify any existing README content.
2. Append ## Docker Setup with the following subsections:
   a. Prerequisites: Docker Desktop 4.x+ (Windows/Mac) or Docker Engine 24+ with Compose plugin (Linux). PostgreSQL running on the host machine. No Node.js required on the host for Docker mode.
   b. Quick Start: (1) Copy env template and fill in values. (2) docker build -t vdrf:latest . (3) docker-compose up. Access app at http://localhost:8000.
   c. Environment Variables (.env.docker): Markdown table — Variable, Required, Example, Notes. Cover all variables from Subtask 4. Highlight ALLOWED_HOSTS JSON array format with example.
   d. External Database Connection: Explain DB_HOST=host.docker.internal for Windows/Mac. For Linux: change DB_HOST to 172.17.0.1 or run ip route show default | awk '/default/ {print }'. The extra_hosts entry in docker-compose.yml resolves this automatically on Linux.
   e. Non-Docker Development (unchanged): npm run dev (port 3000) and python manage.py runserver (port 8000) continue to work exactly as before. Docker files are purely additive.
   f. Useful Commands: docker-compose logs -f, docker exec -it vdrf-web bash, docker exec vdrf-web python manage.py migrate, docker exec vdrf-web python manage.py dbshell, docker exec vdrf-web python -m pytest backend/tests/ -v.
   g. Troubleshooting: json.JSONDecodeError at startup = ALLOWED_HOSTS not a valid JSON array. DB connection refused = wrong DB_HOST for your OS; check PostgreSQL listens on 0.0.0.0:5432. Blank page = Vite build may have failed inside Docker; check npm install output in build log.
   h. Heroku Compatibility: Dockerfile and docker-compose.yml are ignored by Heroku when a Procfile is present and app uses standard buildpacks. No Heroku configuration changes needed.

**Testing:**

- Each command in the Docker Setup section is verified as copy-paste runnable.
- The ALLOWED_HOSTS format note is present.
- The Linux DB host workaround is documented.
- The ## Docker Setup section appears after all existing README content.

---

### Subtask 8: Test Docker Build Completes Without Error

**AC Mapping:** Scenario 1 (Docker Build and Startup) — docker build -t vdrf:latest . exits with code 0.

**Files to change:**

- None — validation subtask.

**Steps:**

1. From C:\projects\AppDev\VDRF_Template, run docker build -t vdrf:latest .
2. Monitor each stage: apt-get installs libpq-dev/gcc/nodejs cleanly; npm install resolves all packages from package.json without lock file error; npm run build outputs dist/index.html; pip install installs all packages including compiled psycopg2.
3. If Node memory error during vite build: add ENV NODE_OPTIONS=--max-old-space-size=2048 before the build RUN step in the Dockerfile.
4. If psycopg2 compile fails: confirm libpq-dev and gcc are installed in the Dockerfile apt-get step.
5. Verify post-build: docker run --rm vdrf:latest ls /app/dist shows index.html and static/.

**Testing:**

- docker build exit code is 0.
- docker images vdrf:latest shows the image with non-zero size.
- docker run --rm vdrf:latest ls /app/dist/static/js shows at least one .js file.

---

### Subtask 9: Test docker-compose up Starts and Vue SPA Renders

**AC Mapping:** Scenario 2 (Container Execution) and Scenario 4 (Frontend Asset Serving).

**Files to change:**

- None — validation subtask.

**Steps:**

1. Populate .env.docker with real values: PostgreSQL credentials, a real DJANGO_SECRET_KEY, and ALLOWED_HOSTS=["localhost","127.0.0.1"].
2. Run docker-compose up.
3. Confirm in container logs: DEBUG Mode: True (dev.py line 34 print), gunicorn startup line Listening at: http://0.0.0.0:8000, no json.JSONDecodeError.
4. Open http://localhost:8000 in a browser. Confirm the Vue 3 / Vuetify SPA renders (login page visible).
5. Check DevTools Network tab: JS and CSS assets at /static/js/*.js and /static/css/*.css return HTTP 200 (WhiteNoise serving from /app/dist/static/).
6. If / returns Django 404: check backend/urls.py for a catch-all pattern serving dist/index.html. This is a pre-existing URL routing concern, not Docker-specific.

**Testing:**

- GET http://localhost:8000 returns HTTP 200 with <div id="app"> in the response body.
- GET http://localhost:8000/static/js/<filename>.js returns HTTP 200.
- docker-compose logs shows no ERROR-level lines after startup.

---

### Subtask 10: Test API Endpoints and External PostgreSQL Connection

**AC Mapping:** Scenario 3 (External Database Connection) and Scenario 4 (API Endpoints Accessible).

**Files to change:**

- None — validation subtask.

**Steps:**

1. docker exec vdrf-web python manage.py dbshell — a psql prompt opening confirms DB_* vars are correct and host.docker.internal resolves to host PostgreSQL.
2. Run migrations: docker exec vdrf-web python manage.py migrate.
3. Test auth endpoint: POST to http://localhost:8000/api/auth/obtain_token/ with JSON body. Expect HTTP 400 (invalid credentials) or 200 — either confirms Django processes requests and DB is reachable.
4. If DB connection fails with Connection refused on Windows/Mac: confirm DB_HOST=host.docker.internal and PostgreSQL listens on 0.0.0.0:5432. On Linux: change DB_HOST to 172.17.0.1 and confirm extra_hosts is in docker-compose.yml.
5. Run pytest inside container: docker exec vdrf-web python -m pytest backend/tests/ -v. All existing tests should pass.

**Testing:**

- docker exec vdrf-web python manage.py dbshell opens a psql prompt without error.
- POST to /api/auth/obtain_token/ returns HTTP 400 or 200, not 500.
- manage.py migrate reports No migrations to apply or applies cleanly.

---

### Subtask 11: Verify Non-Docker Development is Unchanged

**AC Mapping:** Scenario 5 (Non-Docker Development Unchanged) — new Docker files must not disrupt the standard npm + Django runserver workflow.

**Files to change:**

- None — validation subtask.

**Steps:**

1. On the host machine (outside Docker), run npm run dev from the project root. Confirm Vite starts on port 3000 (vite.config.mjs line 69: server: { port: 3000 }).
2. In a separate terminal, run python manage.py runserver. Confirm Django reads backend/.env via load_dotenv() and starts on port 8000.
3. Navigate to http://localhost:3000 and confirm Vue SPA with hot-reload.
4. Navigate to http://localhost:8000/api/auth/obtain_token/ and confirm API responds.
5. Confirm .env.docker in the project root does NOT affect the non-Docker Django process. load_dotenv() at dev.py line 24 loads backend/.env (not the project-root .env.docker). Docker env vars never interfere.
6. Run python -m pytest backend/tests/ -v on the host and confirm the same test results as before the Docker files were added.

**Testing:**

- npm run dev starts without errors; http://localhost:3000 renders the SPA.
- python manage.py runserver starts without errors.
- Pytest suite passes identically to pre-Docker baseline.

---

### Subtask 12: Verify Heroku Deployment is Unaffected

**AC Mapping:** Edge Case (Heroku deployment conflicts) — Docker files must not interfere with the existing Heroku pipeline.

**Files to change:**

- None — validation subtask.

**Steps:**

1. Confirm Procfile is unchanged: release: python manage.py migrate and web: gunicorn backend.wsgi --log-file -
2. Check for runtime.txt at C:\projects\AppDev\VDRF_Template\runtime.txt. If present, confirm it is unchanged.
3. Confirm requirements.txt is unchanged — no Docker-specific packages added (gunicorn, psycopg2-binary, whitenoise are already present).
4. Verify heroku.yml does NOT exist in the project root. Heroku uses Docker only when heroku.yml is present AND the app stack is set to container. Without heroku.yml, Heroku ignores Dockerfile and uses standard buildpacks.
5. Run git diff HEAD -- Procfile requirements.txt on the feature branch. Output must be empty.
6. Run git diff HEAD --name-only and confirm only: Dockerfile, docker-compose.yml, .dockerignore, .env.docker (template), .gitignore (one rule added), README.md (section appended).

**Testing:**

- git diff HEAD -- Procfile returns empty.
- heroku.yml does not exist in the repo root.
- If Heroku staging is available: push confirms Heroku build uses Python buildpack, not Docker.

---

## Next Steps

- [ ] Create the working branch: git checkout -b VDRF_Dockerize_34 from main
- [ ] Execute Subtask 2 (.dockerignore) before the first docker build to keep the build context small
- [ ] Execute Subtask 1 (Dockerfile) — all validation subtasks depend on a buildable image
- [ ] Execute Subtasks 3 and 4 (docker-compose.yml + .env.docker) together — consumed as a pair
- [ ] Execute Subtask 5 (.gitignore update) immediately after creating .env.docker to prevent accidental secret commit
- [ ] Review Subtask 6 (settings compatibility) before first docker-compose up to confirm no missing env vars
- [ ] Execute Subtask 7 (README) so documentation ships with the feature in the same commit
- [ ] Run validation Subtasks 8-12 in order before opening the PR
- [ ] Open PR from VDRF_Dockerize_34 into main
