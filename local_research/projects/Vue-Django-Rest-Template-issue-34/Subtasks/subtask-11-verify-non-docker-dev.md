### Subtask 11: Verify Non-Docker Development is Unchanged

**AC Mapping:** Scenario 5 (Non-Docker Development Unchanged) — new Docker files must not disrupt the standard npm + Django runserver workflow.

**Files to change:**

- None — validation subtask.

**Steps:**

1. On the host machine (outside Docker), run npm run dev from the project root. Confirm Vite starts on port 3000 (vite.config.mjs line 69: server: { port: 3000 }).
2. In a separate terminal, run python manage.py runserver. Confirm Django reads backend/.env via load_dotenv() (dev.py line 24) and starts on port 8000.
3. Navigate to http://localhost:3000 and confirm the Vue SPA renders with hot-reload.
4. Navigate to http://localhost:8000/api/auth/obtain_token/ and confirm the API responds.
5. Confirm .env.docker in the project root does NOT affect the non-Docker Django process. load_dotenv() at dev.py line 24 loads backend/.env (not the project-root .env.docker). Docker env vars are never injected into the non-Docker process.
6. Run python -m pytest backend/tests/ -v on the host and confirm identical test results to the pre-Docker baseline.

**Testing:**

- npm run dev starts without errors; http://localhost:3000 renders the SPA.
- python manage.py runserver starts without errors; http://localhost:8000 responds.
- Pytest suite passes with the same results as before the Docker files were added.
