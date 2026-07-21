# Planka-issue-1 -- Subtask 3: Create `src/planka_tools/jobs/base.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

---

### Subtask 3: Create `src/planka_tools/jobs/base.py`

**AC Mapping:** Defines the job contract used by all subsequent subtasks (AC #2, #4)
**Files to change:**

- `src/planka_tools/jobs/base.py` — new file, docstrings only (no runtime logic)

**Steps:**

1. Document the `ScheduledJob` module contract as a docstring:
   ```python
   """
   base.py — Job module contracts (documentation only; no runtime classes).

   A "Scheduled" job module (under jobs/Scheduled/) must define:
       TRIGGER: dict   — APScheduler trigger kwargs, e.g.:
           {"type": "cron", "hour": 8, "minute": 0}
           {"type": "cron", "day": 1, "hour": 4, "minute": 0}
           {"type": "interval", "hours": 6}
       def run(client: PlankaClient) -> None: ...

   A "Webhook" job module (under jobs/Webhook/) must define:
       EVENTS: list[str]   — Planka event names this job subscribes to, e.g. ["cardUpdate"]
       def run(event: str, payload: dict, client: PlankaClient) -> None: ...
   """
   ```
2. No classes/functions required — `loader.py` (Subtask 4) validates these attributes with `hasattr`/`getattr`, it does not import this module at runtime. Keep `base.py` as living documentation referenced from `COMMANDS.md` (Subtask 19).

**Testing:**

- N/A (documentation-only file); covered by review, not automated tests.

