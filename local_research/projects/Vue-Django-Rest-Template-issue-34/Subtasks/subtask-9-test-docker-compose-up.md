### Subtask 9: Test docker-compose up Starts and Vue SPA Renders

**AC Mapping:** Scenario 2 (Container Execution) and Scenario 4 (Frontend Asset Serving).

**Files to change:**

- None — validation subtask.

**Steps:**

1. Populate .env.docker with real values: PostgreSQL credentials, a real DJANGO_SECRET_KEY (50-char random string), and ALLOWED_HOSTS=["localhost","127.0.0.1"].
2. Run docker-compose up from the project root.
3. Confirm in container logs:
   - "DEBUG Mode: True" — printed by dev.py line 34.
   - "[INFO] Starting gunicorn 23.0.0" and "Listening at: http://0.0.0.0:8000".
   - No json.JSONDecodeError (confirms ALLOWED_HOSTS parsed correctly).
4. Open http://localhost:8000 in a browser. Confirm the Vue 3 / Vuetify SPA renders — login page should be visible.
5. Check DevTools Network tab: JS assets at /static/js/*.js and CSS at /static/css/*.css return HTTP 200. These are served by WhiteNoise from /app/dist/static/ inside the container.
6. If / returns a Django 404: check backend/urls.py for a catch-all URL pattern that serves dist/index.html. This would be a pre-existing URL routing gap, not a Docker-specific issue.

**Testing:**

- GET http://localhost:8000 returns HTTP 200 with <div id="app"> in the response body.
- GET http://localhost:8000/static/js/<filename>.js returns HTTP 200.
- docker-compose logs shows no ERROR-level lines after startup.
