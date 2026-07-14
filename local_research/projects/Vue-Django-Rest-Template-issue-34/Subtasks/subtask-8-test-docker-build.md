### Subtask 8: Test Docker Build Completes Without Error

**AC Mapping:** Scenario 1 (Docker Build and Startup) — docker build -t vdrf:latest . exits with code 0.

**Files to change:**

- None — validation subtask; no modifications.

**Steps:**

1. From C:\projects\AppDev\VDRF_Template, run: docker build -t vdrf:latest .
2. Monitor each build stage for errors:
   - apt-get installs libpq-dev, gcc, nodejs cleanly.
   - npm install resolves all packages from package.json without a lock file error.
   - npm run build (vite build) outputs dist/index.html. If Node memory error, add ENV NODE_OPTIONS=--max-old-space-size=2048 before the npm run build RUN step in the Dockerfile.
   - pip install installs all 80+ packages including compiled psycopg2.
3. If vite build fails with missing source files: confirm all frontend COPY steps in the Dockerfile cover src/, index.html, vite.config.mjs.
4. If psycopg2 compile fails: confirm libpq-dev and gcc appear in the Dockerfile apt-get install step before pip install.
5. Post-build verifications:
   - docker run --rm vdrf:latest ls /app/dist shows index.html and static/ directory.
   - docker run --rm vdrf:latest ls /app/dist/static/js shows at least one .js file.

**Testing:**

- docker build exit code is 0.
- docker images vdrf:latest shows the image with non-zero size.
- docker run --rm vdrf:latest ls /app/dist/static/js shows at least one .js chunk file.
