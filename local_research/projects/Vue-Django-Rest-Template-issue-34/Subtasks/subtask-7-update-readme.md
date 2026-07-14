### Subtask 7: Update README.md

**AC Mapping:** All scenarios (documentation) — developers can follow step-by-step instructions to build and run the Docker environment from a fresh clone.

**Files to change:**

- `README.md` (MODIFY at C:\projects\AppDev\VDRF_Template\README.md) — append ## Docker Setup section after all existing content; do not remove or alter existing content

**Steps:**

1. Do not remove or modify any existing README content.
2. Append a ## Docker Setup section containing the following subsections:

   a. Prerequisites: Docker Desktop 4.x+ (Windows/Mac) or Docker Engine 24+ with Compose plugin (Linux). PostgreSQL running on the host machine. No Node.js required on the host for Docker mode.

   b. Quick Start: Three numbered steps — (1) Copy env template and fill in real values. (2) docker build -t vdrf:latest . (3) docker-compose up. Access the app at http://localhost:8000.

   c. Environment Variables (.env.docker): Markdown table with columns Variable, Required, Example, Notes. Include all variables from Subtask 4 (DJANGO_SETTINGS_MODULE, ENV_TYPE, DJANGO_SECRET_KEY, DEBUG, ALLOWED_HOSTS, DB_NAME, DB_HOST, DB_USER, DB_PASSWORD, DB_PORT, AWS_S3, EMAIL_BACKEND, EMAIL_HOST, EMAIL_PORT, EMAIL_HOST_USER, EMAIL_HOST_PASSWORD, EMAIL_USE_TLS). Highlight the ALLOWED_HOSTS JSON array format with a concrete example.

   d. External Database Connection: Explain DB_HOST=host.docker.internal for Windows/Mac. For Linux: change DB_HOST to 172.17.0.1 or run the ip route command to find the gateway IP. Note that the extra_hosts entry in docker-compose.yml resolves host.docker.internal automatically on Linux.

   e. Non-Docker Development (unchanged): Confirm npm run dev (port 3000) and python manage.py runserver (port 8000) continue to work exactly as before. Docker files are purely additive and do not change the non-Docker workflow.

   f. Useful Commands: docker-compose logs -f, docker exec -it vdrf-web bash, docker exec vdrf-web python manage.py migrate, docker exec vdrf-web python manage.py dbshell, docker exec vdrf-web python -m pytest backend/tests/ -v.

   g. Troubleshooting: (1) json.JSONDecodeError at startup = ALLOWED_HOSTS not a valid JSON array; use ["localhost","127.0.0.1"] with brackets. (2) DB connection refused = wrong DB_HOST for your OS; confirm PostgreSQL listens on 0.0.0.0:5432 not just 127.0.0.1. (3) Blank page or missing static assets = Vite build may have failed; check npm install output in docker build log.

   h. Heroku Compatibility: State explicitly that Dockerfile and docker-compose.yml are ignored by Heroku when a Procfile is present and the app uses standard buildpacks (not the container stack). No Heroku configuration changes are needed.

**Testing:**

- Each command in the Docker Setup section is verified as copy-paste runnable against the actual files.
- The ALLOWED_HOSTS JSON array format note is present.
- The Linux DB_HOST workaround is documented.
- The ## Docker Setup section appears after all existing README content.
