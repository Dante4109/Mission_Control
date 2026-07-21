# Planka-issue-1 -- Subtask 15: Write `tests/test_job_loader.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

---

### Subtask 15: Write `tests/test_job_loader.py`

**AC Mapping:** Malformed/missing job file handling (AC #16), auto-discovery correctness (AC #5)
**Files to change:**

- `tests/test_job_loader.py` — new file

**Steps:**

1. Use `tmp_path` (pytest fixture) to create temporary `.py` files, mirroring the mocking style of `tests/test_card_move.py` (MagicMock + patch) but for filesystem-based module loading — no mocking of `importlib` needed, use real temp files:
   - Valid scheduled job (`TRIGGER` + `run` present) → `load_scheduled_jobs` returns 1 module.
   - Valid webhook job (`EVENTS` + `run` present) → `load_webhook_jobs` returns 1 module.
   - Job missing `TRIGGER`/`EVENTS` → skipped, `caplog` captures an ERROR log line.
   - Job missing `run` → skipped, ERROR logged.
   - Job file that raises at import time (e.g., `raise ImportError("boom")` at module scope) → skipped, ERROR logged, no exception propagates.
   - Empty directory → returns `[]`.
   - Nonexistent directory → returns `[]` (per `loader.py`'s `if not jobs_dir.exists(): return modules`).
2. Use `caplog.at_level(logging.ERROR)` to assert log content without mocking the logger.

**Testing:**

- This file *is* the test; run via `pytest tests/test_job_loader.py -v`.

