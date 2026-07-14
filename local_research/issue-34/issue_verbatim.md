# GitHub Issue #34 — Verbatim Content

**Issue URL:** https://github.com/Dante4109/Vue-Django-Rest-Template/issues/34

**Number:** 34
**Title:** VDRF-0034 Dockerize project
**State:** OPEN
**Author:** Dante4109 (RJ Zeller)
**Assignees:** None
**Labels:** enhancement, core
**Created At:** 2026-03-24T20:50:20Z
**Updated At:** 2026-03-26T02:39:18Z
**Comments:** 0

---

## Issue Body

## User Story (BDD Format)

**As a** Developer
**I want** to containerize the VDRF project (Vue frontend + Django backend)
**So that** I can ensure consistent environments across local development, testing, and deployment while maintaining Heroku compatibility

### Acceptance Criteria

**Scenario 1: Docker Build and Startup**
- **Given** the project repository with frontend and backend code
  **When** I build a Docker image with docker build -t vdrf:latest .
  **Then** the image should build successfully with both Python and Node.js dependencies installed

**Scenario 2: Container Execution**
- **Given** a Docker image is built
  **When** I run docker-compose up
  **Then** the container should start and serve both the Vue frontend and Django API on configured ports

**Scenario 3: External Database Connection**
- **Given** the container is running and a PostgreSQL database exists on the host machine
  **When** the Django application attempts to connect using host.docker.internal (Windows/Mac) or 172.17.0.1 (Linux)
  **Then** the database connection should succeed and migrations should execute properly

**Scenario 4: Frontend Asset Serving**
- **Given** the Docker container is running
  **When** I access the application at the configured URL
  **Then** the Vue frontend assets should be served correctly and API endpoints should be accessible

**Scenario 5: Non-Docker Development Unchanged**
- **Given** existing local development setup
  **When** I run the project without Docker (standard npm + python processes)
  **Then** the application should work identically to the Docker version with no project structure changes

### Edge Cases & Error Handling
- Container fails if required environment variables are missing → .env.docker template should document all required vars
- Volume mounts don't reflect changes → Documentation should clarify hot-reload expectations
- External database is unreachable → Clear error messaging in logs with troubleshooting guide
- Heroku deployment conflicts → Docker files should not interfere with existing Heroku deployment

---
## Goals
- Create docker container for frontend and backend
- Still connect to external DB running on desktop for now
- Do not modify project files where you can't deploy to Heroku

## Implementation Plan Summary
A comprehensive implementation plan has been created based on analysis of the django-todo-app Docker setup.

### Key Approach
**Single Container Strategy:**
- One Dockerfile at project root containing both frontend and backend
- Frontend: Vue.js compiled during build to static assets
- Backend: Django serves frontend + API
- Database: External connection to desktop (no docker-managed DB)
- File structure: UNCHANGED (preserves Heroku compatibility)

**Development Modes:**
1. **Without Docker** (Unchanged) - Run frontend and backend separately
2. **With Docker** - Single `docker-compose up` command

### Docker Files to Create
1. **Dockerfile** - Installs Python + Node.js, builds frontend, runs Django
2. **docker-compose.yml** - Orchestrates container, mounts volumes, configures external DB
3. **.dockerignore** - Excludes unnecessary files from build
4. **.env.docker** - Environment template for docker development

### Heroku Compatibility
✅ **Preserved** - No modifications to deployment files
- Dockerfile/docker-compose are optional local development only
- Heroku can ignore Docker and use standard buildpacks
- Project structure unchanged - Procfile/runtime.txt untouched

## Implementation Checklist

### Phase 1: Docker Setup
- [ ] Create Dockerfile (Python 3.10+ base, Node.js, build Vue, run Django)
- [ ] Create docker-compose.yml (web service, external DB, volume mounts)
- [ ] Create .dockerignore (exclude venv, node_modules, etc.)
- [ ] Create .env.docker template
- [ ] Test: `docker build -t vdrf:latest .`
- [ ] Test: `docker-compose up`
- [ ] Verify frontend assets served from /app/frontend/dist
- [ ] Verify API endpoints accessible
- [ ] Verify external database connection works

### Phase 2: Local Development
- [ ] Document non-docker setup (no changes)
- [ ] Document docker setup (new)
- [ ] Update README with Docker instructions
- [ ] Test both methods work identically
- [ ] Verify hot-reload with volume mounts
- [ ] Create debugging guide

### Phase 3: Environment & Deployment
- [ ] Test with actual desktop PostgreSQL
- [ ] Verify Heroku deployment still works
- [ ] Document host.docker.internal for Windows/Mac DB connection
- [ ] Update .gitignore if needed
- [ ] Create troubleshooting guide

### Phase 4: Testing & Validation
- [ ] Run tests in container
- [ ] Test Vue compilation
- [ ] Test API auth/authorization
- [ ] Verify database migrations
- [ ] Performance comparison (docker vs non-docker)
- [ ] OS compatibility (Windows, Mac, Linux)

## Database Configuration

**External Database from Container:**
```yaml
# In docker-compose.yml
environment:
  DATABASE_HOST=host.docker.internal  # Windows/Mac
  DATABASE_HOST=172.17.0.1            # Linux
```

**Verify Connection:**
```bash
docker exec vdrf-app python backend/manage.py dbshell
```

## Acceptance Criteria

- [ ] Frontend containerized and runs locally
- [ ] Backend containerized and runs locally
- [ ] docker-compose.yml enables single command startup
- [ ] External database connection works from containers
- [ ] No modifications break existing Heroku deployment process
- [ ] Non-docker development still works unchanged
- [ ] All files documented in README

## Reference

Based on: `django-todo-app` Docker implementation pattern
- Simple Dockerfile structure
- docker-compose for local development
- Environment variable management
- Volume mounting for hot-reload

---

**Full Plan:** See `VDRF_Dockerization_Plan.md` in project documentation
