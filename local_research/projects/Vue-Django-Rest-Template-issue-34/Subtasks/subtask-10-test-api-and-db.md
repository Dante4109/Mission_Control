### Subtask 10: Test API Endpoints and External PostgreSQL Connection

**AC Mapping:** Scenario 3 (External Database Connection) and Scenario 4 (API Endpoints Accessible).

**Files to change:**

- None — validation subtask.

**Steps:**

1. With the container running, verify DB connection: docker exec vdrf-web python manage.py dbshell. A psql prompt opening confirms DB_* vars in .env.docker are correct and host.docker.internal resolves to the host PostgreSQL.
2. Run migrations: docker exec vdrf-web python manage.py migrate. Should apply existing migrations cleanly or report No migrations to apply.
3. Test auth endpoint: POST to http://localhost:8000/api/auth/obtain_token/ with Content-Type: application/json and a JSON body. Expect HTTP 400 (invalid credentials) or 200 (valid) — either response confirms Django is processing requests and the DB is reachable.
4. If DB connection fails with Connection refused:
   - Windows/Mac: confirm DB_HOST=host.docker.internal and that PostgreSQL on the host listens on 0.0.0.0:5432 (not just 127.0.0.1). Check PostgreSQL pg_hba.conf and postgresql.conf listen_addresses.
   - Linux: change DB_HOST to 172.17.0.1 and confirm extra_hosts is in docker-compose.yml. Run sudo netstat -tlnp | grep 5432 on the host to confirm PostgreSQL is listening.
5. Run the existing pytest suite inside the container: docker exec vdrf-web python -m pytest backend/tests/ -v. All existing tests should pass — no new failures introduced by the Docker setup.

**Testing:**

- docker exec vdrf-web python manage.py dbshell opens a psql prompt without error.
- POST to /api/auth/obtain_token/ returns HTTP 400 or 200, not 500.
- manage.py migrate reports No migrations to apply or applies cleanly.
