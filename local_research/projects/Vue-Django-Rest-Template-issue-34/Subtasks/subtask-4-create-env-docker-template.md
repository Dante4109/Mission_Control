### Subtask 4: Create .env.docker Template

**AC Mapping:** All scenarios — documents every required environment variable with safe placeholder values; prevents cryptic startup errors.

**Files to change:**

- `.env.docker` (NEW at C:\projects\AppDev\VDRF_Template\.env.docker) — committed template with placeholder values only; zero real secrets

**Steps:**

1. Add header comment: ".env.docker — Docker environment template. Fill in real values locally. DO NOT commit filled-in values."
2. `DJANGO_SETTINGS_MODULE=backend.settings.dev` — explicit for clarity, even though backend/wsgi.py line 13 sets it via setdefault.
3. `ENV_TYPE=DEV` — activates the DB_* vars path in dev.py line 131. Without this, Django falls into the Heroku DATABASE_URL branch and fails to connect.
4. `DJANGO_SECRET_KEY=your-secret-key-change-me` — read by dev.py line 30 (SECRET_KEY = os.getenv("DJANGO_SECRET_KEY")).
5. `DEBUG=True` — read by dev.py line 33. String "True" is truthy in this project; Django uses it as-is.
6. `ALLOWED_HOSTS=["localhost","127.0.0.1"]` — CRITICAL: dev.py line 36 does json.loads(os.getenv("ALLOWED_HOSTS")). Must be a valid JSON array string including square brackets. Any other format raises json.JSONDecodeError and crashes Django at startup. Add inline comment documenting this constraint and the exact format.
7. Database vars: DB_NAME=your_db_name, DB_HOST=host.docker.internal, DB_USER=your_db_user, DB_PASSWORD=your_db_password, DB_PORT=5432. Add comment: "Linux users: change DB_HOST to 172.17.0.1 or run: ip route show default | awk '/default/ {print }'"
8. `AWS_S3=False` — dev.py line 197 checks if os.getenv("AWS_S3") == "True". String "False" skips the S3 block; local media storage uses mediafiles_cdn/.
9. Email vars: EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend, EMAIL_HOST=, EMAIL_PORT=, EMAIL_HOST_USER=, EMAIL_HOST_PASSWORD=, EMAIL_USE_TLS=. Console backend prints emails to stdout (visible in docker-compose logs) without requiring SMTP. All six vars read unconditionally in dev.py lines 227-232.

**Testing:**

- Cross-reference every os.getenv() call in backend/settings/dev.py against this template — no call should be missing a corresponding entry.
- docker-compose up with real DB credentials in .env.docker starts Django without KeyError, json.JSONDecodeError, or ImproperlyConfigured.
