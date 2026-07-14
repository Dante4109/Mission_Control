### Subtask 3: Create docker-compose.yml

**AC Mapping:** Scenario 2 (Container Execution) — docker-compose up starts container on port 8000; Scenario 3 (External DB) — extra_hosts enables Linux host DB resolution.

**Files to change:**

- `docker-compose.yml` (NEW at C:\projects\AppDev\VDRF_Template\docker-compose.yml) — single web service; no database container

**Steps:**

1. Omit the version: key — deprecated in Compose v2+.
2. Define a single service `web:` under services: (no database service; PostgreSQL runs on the host machine).
3. Set `build: .` to build from the Dockerfile at the project root.
4. Set `container_name: vdrf-web` for predictable naming in docker exec and docker logs commands.
5. Set `ports: ["8000:8000"]` to expose Django/gunicorn on the host at http://localhost:8000.
6. Set `env_file: .env.docker` to load all environment variables from the template file at container startup. Avoids baking secrets into the image or compose file.
7. Add `extra_hosts: ["host.docker.internal:host-gateway"]`. On Linux, this maps host.docker.internal to the host gateway IP so DB_HOST=host.docker.internal resolves correctly. On Windows and Mac, Docker Desktop provides this natively; the entry is harmless on those platforms.
8. Do NOT add a volumes mount for ./dist:/app/dist. Vite builds dist/ inside the image at build time; a host volume mount would shadow the built dist/ with empty or stale local files, breaking static asset serving.
9. Optionally include a commented-out `volumes: ["./backend:/app/backend"]` for Django hot-reload without full image rebuilds. Leave commented out by default to keep the default experience simple.

**Testing:**

- `docker-compose config` validates YAML with no errors.
- `docker-compose up` with a valid .env.docker starts the container.
- `curl http://localhost:8000` returns an HTTP response.
