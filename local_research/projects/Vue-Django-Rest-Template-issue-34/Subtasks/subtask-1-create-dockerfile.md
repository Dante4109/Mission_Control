### Subtask 1: Create Dockerfile

**AC Mapping:** Scenario 1 (Docker Build and Startup) — image builds with Python 3.12 and Node.js; npm run build compiles Vue assets into dist/; gunicorn starts Django on port 8000.

**Files to change:**

- `Dockerfile` (NEW at C:\projects\AppDev\VDRF_Template\Dockerfile) — single-stage build: Python 3.12 base + Node.js 20 LTS via NodeSource + Vite build + pip install + gunicorn CMD

**Steps:**

1. Use `FROM python:3.12` as the base image. Matches the reference django-todo-app pattern and satisfies Django 5.1.1's Python 3.10+ requirement.
2. Install system deps with apt-get: curl (for NodeSource script), libpq-dev and gcc (required by the non-binary psycopg2 package in requirements.txt). Clean apt lists afterward.
3. Install Node.js 20 LTS via NodeSource setup script. This gives both node and npm in the same image layer without a multi-stage build.
4. Set `WORKDIR /app`.
5. Copy `package.json` only (NOT package-lock.json — it is gitignored and absent from fresh clones). Run `npm install` (NOT npm ci — lock file is gitignored). This layer is cached as long as package.json does not change.
6. Copy frontend source files required by Vite: `src/`, `index.html`, `vite.config.mjs`, `.browserslistrc`, `.eslintrc.js`, and `public/` if present. Run `npm run build` (maps to vite build per package.json). Vite writes to /app/dist/; JS at /app/dist/static/js/, CSS at /app/dist/static/css/ — matching Django STATIC_ROOT = BASE_DIR / "dist" / "static" (dev.py line 189).
7. Copy `requirements.txt` and run pip install with --no-cache-dir. Installs gunicorn 23.0.0, psycopg2-binary 2.9.9, whitenoise 6.7.0, and all other dependencies.
8. Copy remaining project files with `COPY . .`. Placed last to maximize Docker layer cache reuse.
9. Add `EXPOSE 8000`.
10. Set CMD to `["gunicorn", "backend.wsgi", "--log-file", "-"]` to mirror the Procfile web: process. backend/wsgi.py line 13 calls os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings.dev"), so settings resolve correctly.
11. Do NOT add a collectstatic step. STATICFILES_DIRS in dev.py lines 190-195 points into subdirectories of STATIC_ROOT; collectstatic fails when source and destination overlap. WhiteNoiseMiddleware in MIDDLEWARE (dev.py line 72) serves files from STATIC_ROOT directly.

**Testing:**

- `docker build -t vdrf:latest .` exits with code 0.
- `docker run --rm vdrf:latest ls /app/dist` shows index.html and static/ directory.
- `docker inspect vdrf:latest --format='{{.Config.Cmd}}'` returns [gunicorn backend.wsgi --log-file -].
