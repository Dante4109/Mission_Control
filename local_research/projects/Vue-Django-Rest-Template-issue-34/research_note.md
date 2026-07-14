# Research Note — Issue #34: VDRF-0034 Dockerize project

**Issue URL:** https://github.com/Dante4109/Vue-Django-Rest-Template/issues/34
**Date Started:** 2026-06-24
**Status:** OPEN
**Author:** Dante4109 (RJ Zeller)
**Assignees:** None
**Labels:** enhancement, core
**Milestone:** None

---

## Issue Summary

Containerize the VDRF (Vue-Django-Rest-Template) project to ensure consistent environments across local development, testing, and deployment while maintaining Heroku compatibility. The solution uses a single Docker container with both Vue frontend and Django backend, connecting to an external PostgreSQL database, without modifying project structure or breaking existing Heroku deployments.

## Acceptance Criteria

- [ ] Docker image builds successfully with both Python and Node.js dependencies installed
- [ ] `docker-compose up` starts the container and serves both Vue frontend and Django API on configured ports
- [ ] Django container connects to external PostgreSQL database on host (host.docker.internal for Windows/Mac, 172.17.0.1 for Linux)
- [ ] Vue frontend assets are served correctly and API endpoints are accessible
- [ ] Non-Docker development (standard npm + python processes) works identically with no project structure changes
- [ ] Dockerfile, docker-compose.yml, .dockerignore, and .env.docker template are created
- [ ] Environment variables documented in .env.docker template
- [ ] Heroku deployment process remains unchanged and functional
- [ ] Hot-reload with volume mounts works in docker development
- [ ] OS compatibility verified (Windows, Mac, Linux)

## Key Files / Areas of Codebase

**Files to Create:**
- `Dockerfile` (project root) — Python 3.10+ base, Node.js, Vue build, Django execution
- `docker-compose.yml` (project root) — Orchestration, external DB config, volume mounts
- `.dockerignore` (project root) — Exclude venv, node_modules, etc.
- `.env.docker` (project root) — Environment variable template
- README updates — Docker setup instructions

**Existing Project Structure (to preserve):**
- `frontend/` — Vue.js application
- `backend/` — Django application
- `Procfile` — Heroku deployment (must remain unchanged)
- `runtime.txt` — Heroku Python version
- Existing Heroku deployment configuration

**Repository:** https://github.com/Dante4109/Vue-Django-Rest-Template

## Open Questions

1. **Frontend build location:** Should compiled Vue assets be placed in `/app/frontend/dist` or serve via Django's static files?
2. **Database migrations:** Should migrations run automatically on container startup or be manual?
3. **Environment variables:** What's the exact scope of variables needed in .env.docker (DB credentials, Django settings, etc.)?
4. **Hot-reload behavior:** Is hot-reload expected to work in docker development mode (volume mounts), or is it a rebuild scenario?
5. **Port mapping:** What ports should be exposed in docker-compose.yml for frontend and API?
6. **Testing in container:** Should tests run as part of the docker build or separately?

## Additional Context / Notes

**Implementation Strategy:**
- Single container approach (not separate frontend/backend containers)
- Frontend compiled to static assets during Docker build
- Django serves both API and static frontend files
- External database connection (no docker-managed database)
- File structure remains unchanged for Heroku compatibility

**Reference Pattern:**
This issue references a Django-todo-app Docker implementation pattern as a reference for structure and approach.

**Development Modes:**
1. Without Docker: npm + python processes (unchanged)
2. With Docker: `docker-compose up` single command

**Known Constraints:**
- Cannot modify project files in ways that break Heroku deployment
- Must preserve existing file structure
- Heroku buildpacks should continue to work for Heroku deployments

---

## Branch

**Branch Name:** `feature/issue-34-dockerize-vdrf`
**Status:** Created and active
**Repository:** C:\projects\AppDev\VDRF_Template

