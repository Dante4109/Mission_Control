# Planka-issue-1 -- Subtask 8: Extend `webhook/handlers.py` with job dispatch

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

---

### Subtask 8: Extend `webhook/handlers.py` with job dispatch

**AC Mapping:** Webhook event triggers matching job (AC #3, #4), missing card/list handling (AC #13), per-job failure isolation (AC #15)
**Files to change:**

- `src/planka_tools/webhook/handlers.py` — extend `handle_event()` (lines 55-96)

**Steps:**

1. Add imports: `from pathlib import Path`, `from planka_tools.jobs import loader`, `import os`.
2. Add a `_jobs_dir()` helper (mirrors runner.py's, or import a shared one — simplest: duplicate the small helper here to avoid a circular import between `scheduler` and `webhook` packages):
   ```python
   def _jobs_dir() -> Path:
       override = os.environ.get("JOBS_DIR")
       base = Path(override) if override else Path(__file__).resolve().parents[1] / "jobs"
       return base
   ```
3. At the end of `handle_event()` (after line 95, i.e. after the existing `sync_list_point_totals` try/except block — do not replace it, only append), add:
   ```python
   for module in loader.load_webhook_jobs(_jobs_dir() / "Webhook"):
       if event not in getattr(module, "EVENTS", []):
           continue
       try:
           module.run(event, payload, client)
       except Exception as exc:
           log.error("Webhook job %s failed on event '%s': %s", module.__name__, event, exc)
   ```
4. Important: the existing early `return` at line 81 (`else: log.debug(...); return`) only triggers for event types not in `("customFieldValueUpdate", "customFieldValueDelete", "cardUpdate", "cardDelete")`. Discovered webhook jobs must still be dispatched even for event types the *existing* dispatcher doesn't otherwise handle (e.g., a future `cardCreate` job) — move the discovered-job dispatch loop so it runs **before** that early return, or restructure so it runs regardless of which branch was taken. Recommended: run the discovered-job loop unconditionally at the very top of `handle_event()`, before the existing board_id-extraction logic, so it's independent of the legacy `sync_list_point_totals` path entirely.

**Testing:**

- Covered by Subtask 18 (`tests/test_webhook_handlers_jobs.py`).

