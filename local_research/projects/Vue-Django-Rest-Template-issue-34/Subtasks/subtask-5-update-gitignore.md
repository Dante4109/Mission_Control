### Subtask 5: Update .gitignore

**AC Mapping:** All scenarios (security) — developer-filled .env.docker with real credentials is never committed to version control.

**Files to change:**

- `.gitignore` (MODIFY at C:\projects\AppDev\VDRF_Template\.gitignore) — add exclusion rule after line 20 (end of # local env files section)

**Steps:**

1. Open .gitignore. The # local env files section at lines 12-20 already excludes .env, .env_prod, .env_prod_heroku, .env_old, .env_other.
2. Choose a commit strategy — two valid options:
   - Option A (recommended): Commit .env.docker as the placeholder template (safe values only). Add .env.docker.local to .gitignore. Developers copy to .env.docker.local, fill in real values, and update docker-compose env_file reference to .env.docker.local.
   - Option B: Commit .env.docker.template as the placeholder. Add .env.docker to .gitignore. Developers run cp .env.docker.template .env.docker. docker-compose env_file references .env.docker by default.
3. After line 20 (.venv.*.local), insert:
   - A blank line
   - A comment explaining the strategy chosen
   - The gitignore rule (.env.docker.local for Option A, or .env.docker for Option B)
4. Do not modify any other section of .gitignore.

**Testing:**

- `git check-ignore -v .env.docker.local` (Option A) or `git check-ignore -v .env.docker` (Option B) confirms the rule fires.
- `git status` after filling in real values confirms the secrets file does not appear as staged or untracked.
- The placeholder template IS tracked: `git ls-files .env.docker` (Option A) or `git ls-files .env.docker.template` (Option B) returns the filename.
