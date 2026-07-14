### Subtask 2: Create .dockerignore

**AC Mapping:** Scenario 1 (Docker Build and Startup) — prevents local artifacts from entering the image; keeps build context small.

**Files to change:**

- `.dockerignore` (NEW at C:\projects\AppDev\VDRF_Template\.dockerignore) — excludes large/irrelevant directories from the Docker build context

**Steps:**

1. Exclude `node_modules` — prevents local node_modules/ (potentially hundreds of MB) from being sent to the Docker daemon. Dockerfile rebuilds it inside the container via npm install.
2. Exclude `venv` and `.venv` — Python virtual environments; not needed in the container.
3. Exclude `dist` — any locally compiled Vite output must not bleed into the image. Vite rebuilds dist/ from source inside the container. Without this, stale local dist/ shadows the container-built output.
4. Exclude `__pycache__`, `.pytest_cache` — compiled Python bytecode and test cache artifacts.
5. Exclude `.env*` — prevents any .env, .env_prod, .env_other, .env.docker file with real secrets from being baked into an image layer. Env vars are injected at runtime via docker-compose env_file.
6. Exclude `mediafiles_cdn` — user-uploaded media files; large and irrelevant to the build.
7. Exclude `.coverage`, `htmlcov` — pytest coverage artifacts.
8. Exclude `cypress` — end-to-end test directory.
9. Exclude `.git` — version history not needed in the image.

**Testing:**

- Build context size shown by docker build should be under 10 MB.
- `docker run --rm vdrf:latest ls /app` must NOT show node_modules, venv, or mediafiles_cdn.
- `docker run --rm vdrf:latest ls /app/dist` shows only the container-built Vite output (no local developer artifacts).
