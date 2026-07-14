### Subtask 6: Verify backend/settings/dev.py Docker Compatibility

**AC Mapping:** Scenario 3 (External DB), Scenario 5 (Non-Docker unchanged) — read-only verification; no code changes expected or needed.

**Files to change:**

- None — read-only verification subtask. No file modifications.

**Steps:**

1. Confirm load_dotenv at dev.py line 24 loads backend/.env with override=False (python-dotenv default). Docker-injected env vars are set before the Python process starts and take precedence over any backend/.env values. No settings file changes needed.
2. Confirm ALLOWED_HOSTS = json.loads(os.getenv("ALLOWED_HOSTS")) at dev.py line 36 requires a JSON array string. Verify .env.docker sets ALLOWED_HOSTS=["localhost","127.0.0.1"] — including the square brackets.
3. Confirm the ENV_TYPE == "DEV" branch at dev.py line 131 activates DB_* vars. The else branch calls dj_database_url.config(ssl_require=True) — without DATABASE_URL this raises ConfigurationError. Confirm .env.docker does NOT set DATABASE_URL when ENV_TYPE=DEV.
4. Confirm STATIC_ROOT = os.path.join(BASE_DIR, "dist", "static") at dev.py line 189 and TEMPLATES DIRS: ["dist", "backend/users"] at dev.py line 109. Inside the container BASE_DIR = /app (the WORKDIR), so STATIC_ROOT = /app/dist/static. Vite's build.outDir: 'dist' (vite.config.mjs line 73) and assetFileNames routes (lines 80-99) output JS to dist/static/js/, CSS to dist/static/css/ — these paths align exactly with Django's expectations.
5. Confirm STATICFILES_DIRS at dev.py lines 190-195 references subdirectories inside STATIC_ROOT. Do NOT call python manage.py collectstatic in the Dockerfile or entrypoint — source/destination overlap causes Django CommandError. WhiteNoiseMiddleware (MIDDLEWARE line 72) serves files from STATIC_ROOT at runtime.
6. Confirm all six EMAIL_* vars at dev.py lines 227-232 use os.getenv() with no fallback — None is acceptable when EMAIL_BACKEND is django.core.mail.backends.console.EmailBackend.

**Testing:**

- No code execution required. Verification is complete when the developer confirms each point above by reading dev.py.
- Optional post-startup check: docker exec vdrf-web python -c "import os; print(os.environ.get('ENV_TYPE'))" should print DEV.
- Optional: docker exec vdrf-web python -c "from backend.settings import dev; print(dev.ALLOWED_HOSTS)" confirms the JSON parse succeeded.
