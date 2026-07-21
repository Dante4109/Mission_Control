# Planka-issue-1 -- Subtask 19: Update `COMMANDS.md`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

---

### Subtask 19: Update `COMMANDS.md`

**AC Mapping:** Documentation completeness (Proposed Subtasks item; not tied to a runtime AC)
**Files to change:**

- `COMMANDS.md` — add new section

**Steps:**

1. Add a "Job System" section documenting:
   - Directory layout (`src/planka_tools/jobs/Scheduled/`, `.../Webhook/`)
   - The `TRIGGER` dict format (cron vs interval, valid keys) and `EVENTS` list format, referencing `jobs/base.py`'s contract docstrings (Subtask 3)
   - `AUTO_ASSIGN_USER_ID` and `JOBS_DIR` environment variables (defaults, purpose)
   - Step-by-step instructions for adding a new job (create file in the right folder, define required attributes, restart `pt scheduler run` or the webhook server to pick it up)
   - Note that job scripts are dynamically imported (`loader.py`) and should only come from trusted sources (per analysis Risks section — dynamic import security)

**Testing:**

- N/A (documentation); review for accuracy against the final implementation.

