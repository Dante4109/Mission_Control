# Planka-issue-1 — Implementation Plan: Scheduled and Webhook-Driven Job System for Planka Tools

**Date:** 2026-07-20
**Branch:** feature/issue-1-job-system
**GH:** https://github.com/Dante4109/Planka/issues/1

## Overview

Add a plugin-style job discovery layer (`src/planka_tools/jobs/`) on top of the existing APScheduler runner (`scheduler/runner.py`) and Flask webhook dispatcher (`webhook/handlers.py`). Job scripts are isolated `.py` files under `jobs/Scheduled/` (module-level `TRIGGER` dict + `run(client)`) or `jobs/Webhook/` (module-level `EVENTS` list + `run(event, payload, client)`), auto-imported by a `loader.py`. The runner registers discovered scheduled jobs with `CronTrigger`; the webhook handler dispatches discovered webhook jobs by event type. One new `PlankaClient` method (`add_member_to_card`) and five example job scripts round out the acceptance criteria. Subtasks compose in dependency order: client method → jobs package/contract → loader → runner/handler integration → example jobs → CLI listing → tests → docs.

**Correction to prior analysis:** `GH_Issue_Analyze.md` assumed `add_member_to_card` should `POST /api/cards/{card_id}/card-members` (by analogy to `add_label_to_card` → `/card-labels`). However, `client.py:261-263` already has `remove_member_from_card(card_id, user_id)` implemented as `DELETE /api/cards/{card_id}/members/{user_id}` — note the resource is `members`, not `card-members`/`card-memberships`, and it addresses by `user_id` directly rather than a membership ID. The add method must mirror this existing sibling, not the label pattern. Subtask 1 below reflects the corrected endpoint. Still recommend a live smoke test before wiring into the webhook job (per gh-issue-analyzer's follow-up note).

## Subtasks

### Subtask 1: Add `add_member_to_card` to `client.py`

**AC Mapping:** "Auto-assign on In-Progress" webhook job assigns configured user (research_note.md AC #11); enables job-to-client integration (AC #2, #6)
**Files to change:**

- `src/planka_tools/api/client.py` — add new method near `remove_member_from_card` (line ~263)

**Steps:**

1. Add directly below `remove_member_from_card` (client.py:261-263):
   ```python
   def add_member_to_card(self, card_id: str, user_id: str) -> dict:
       """Add a member to a card. Mirrors remove_member_from_card's endpoint shape."""
       return self._post(f"/api/cards/{card_id}/members", json={"userId": user_id})["item"]
   ```
   Use `POST /api/cards/{card_id}/members` (matching the existing `DELETE /api/cards/{card_id}/members/{user_id}` resource path) — **not** `/card-members` as the original analysis assumed.
2. Before wiring this into Subtask 13, do a one-off live smoke test: `with PlankaClient() as c: c.add_member_to_card(<real_card_id>, <real_user_id>)` against the dev Planka instance and confirm no `PlankaError`. If the endpoint is wrong, `PlankaError` will surface the real status/error code — adjust the path accordingly.

**Testing:**

- Manual live smoke test as in step 2.
- Unit test added alongside existing `client.py` tests (if any exist) mocking `_post`; otherwise covered indirectly via Subtask 17 (`test_jobs_webhook.py`) with a mocked `PlankaClient`.

---

### Subtask 2: Create `src/planka_tools/jobs/__init__.py`

**AC Mapping:** Foundational — enables job package structure (supports AC #5, auto-discovery)
**Files to change:**

- `src/planka_tools/jobs/__init__.py` — new, empty file

**Steps:**

1. Create empty `__init__.py` to mark `jobs` as a regular package (matches style of other `planka_tools` subpackages — no `__all__`, no re-exports).

**Testing:**

- Import check: `python -c "import planka_tools.jobs"` succeeds with no error.

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

---

### Subtask 4: Create `src/planka_tools/jobs/loader.py`

**AC Mapping:** Auto-discovery (AC #5), malformed job handling (AC #16), no-crash isolation (AC #6, #15)
**Files to change:**

- `src/planka_tools/jobs/loader.py` — new file

**Steps:**

1. Implement using `importlib.util.spec_from_file_location` / `module_from_spec` (not package-relative import, since job files aren't declared in `__init__.py`):
   ```python
   import importlib.util
   import logging
   from pathlib import Path
   from types import ModuleType

   log = logging.getLogger(__name__)

   def _load_module_from_path(path: Path) -> ModuleType:
       spec = importlib.util.spec_from_file_location(path.stem, path)
       module = importlib.util.module_from_spec(spec)
       spec.loader.exec_module(module)
       return module

   def load_scheduled_jobs(jobs_dir: Path) -> list[ModuleType]:
       return _load_jobs(jobs_dir, required_attrs=("TRIGGER", "run"))

   def load_webhook_jobs(jobs_dir: Path) -> list[ModuleType]:
       return _load_jobs(jobs_dir, required_attrs=("EVENTS", "run"))

   def _load_jobs(jobs_dir: Path, required_attrs: tuple[str, ...]) -> list[ModuleType]:
       modules = []
       if not jobs_dir.exists():
           return modules
       for path in sorted(jobs_dir.glob("*.py")):
           if path.name == "__init__.py":
               continue
           try:
               module = _load_module_from_path(path)
               for attr in required_attrs:
                   if not hasattr(module, attr):
                       raise AttributeError(f"missing required attribute '{attr}'")
               modules.append(module)
           except Exception as exc:
               log.error("Failed to load job module %s: %s", path, exc)
       return modules
   ```
2. Catch the broad `Exception` (not just `ImportError`/`AttributeError`) per Requirements section — any error during `exec_module` (syntax error, runtime error at import time) must be caught, logged, and skipped without crashing the loader.

**Testing:**

- Covered by Subtask 15 (`tests/test_job_loader.py`).

---

### Subtask 5: Create `src/planka_tools/jobs/Scheduled/__init__.py`

**AC Mapping:** Supports directory-based job discovery (AC #5)
**Files to change:**

- `src/planka_tools/jobs/Scheduled/__init__.py` — new, empty file

**Steps:**

1. Create empty file so `Scheduled/` is a regular package directory (loader iterates `*.py` in it via `Path.glob`, but an `__init__.py` keeps it importable/consistent with the rest of the codebase and lets `loader._load_jobs` skip it by name).

**Testing:**

- Import check: `python -c "import planka_tools.jobs.Scheduled"` succeeds.

---

### Subtask 6: Create `src/planka_tools/jobs/Webhook/__init__.py`

**AC Mapping:** Supports directory-based job discovery (AC #5)
**Files to change:**

- `src/planka_tools/jobs/Webhook/__init__.py` — new, empty file

**Steps:**

1. Create empty file, same rationale as Subtask 5.

**Testing:**

- Import check: `python -c "import planka_tools.jobs.Webhook"` succeeds.

---

### Subtask 7: Extend `scheduler/runner.py` with job discovery

**AC Mapping:** APScheduler CronTrigger firing (AC #1), scheduled job execution (AC #2), auto-discovery (AC #5), no-duplicate-fire handling (AC #14, #16)
**Files to change:**

- `src/planka_tools/scheduler/runner.py` — extend `build_scheduler()` (lines 67-90)

**Steps:**

1. Add imports: `from apscheduler.triggers.cron import CronTrigger`, `from planka_tools.jobs import loader`, `from planka_tools.api.client import PlankaClient` (already imported), `import os` for `JOBS_DIR` (`os` already imported).
2. Add a `_jobs_dir()` helper mirroring `_load_env` style:
   ```python
   def _jobs_dir() -> Path:
       override = _load_env("JOBS_DIR")
       base = Path(override) if override else Path(__file__).resolve().parents[1] / "jobs"
       return base
   ```
3. Add `_make_scheduled_job_runner(module)` that wraps a discovered job's `run(client)` in the same try/except pattern as `_make_job` (lines 46-64):
   ```python
   def _make_scheduled_job_runner(module):
       def job():
           log.info("Running discovered job '%s' ...", module.__name__)
           try:
               with PlankaClient() as client:
                   module.run(client)
           except PlankaError as e:
               log.error("API error in job %s: %s", module.__name__, e)
           except Exception as e:
               log.error("Unexpected error in job %s: %s", module.__name__, e)
       job.__name__ = f"jobs_{module.__name__}"
       return job
   ```
4. Add `load_and_register_jobs(scheduler, jobs_dir)`:
   ```python
   def load_and_register_jobs(scheduler: BlockingScheduler, jobs_dir: Path) -> list[str]:
       registered = []
       for module in loader.load_scheduled_jobs(jobs_dir / "Scheduled"):
           trig = dict(module.TRIGGER)
           trig_type = trig.pop("type", "cron")
           trigger = CronTrigger(**trig) if trig_type == "cron" else IntervalTrigger(**trig)
           job_id = f"jobs_{module.__name__}"
           scheduler.add_job(
               _make_scheduled_job_runner(module),
               trigger=trigger,
               id=job_id,
               name=module.__name__,
               max_instances=1,
               coalesce=True,
           )
           registered.append(job_id)
       return registered
   ```
   Note the `jobs_` prefix on job IDs, per the analysis's risk note on ID collisions with `sync_points_{board_id}`.
5. Call `load_and_register_jobs(scheduler, _jobs_dir())` at the end of `build_scheduler()` (line 90), **unconditionally** — do not gate it behind `if not board_ids` (line 72-73 currently returns early with an empty scheduler when no boards are configured; discovered jobs should still register in that case). Restructure so the early return at lines 72-73 also calls `load_and_register_jobs` before returning.

**Testing:**

- Manual: `pt scheduler run` with at least one job script present in `jobs/Scheduled/`, confirm log line "Running discovered job ..." appears at trigger time (or verify via `scheduler.get_jobs()` in a REPL without starting the blocking loop).
- Unit coverage of the trigger-mapping and registration logic via `tests/test_jobs_scheduled.py` is out of scope for this subtask (that file mocks at the job level, not the runner level) — no dedicated runner unit test is listed in Proposed Subtasks; verify manually per above.

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

---

### Subtask 9: Implement `jobs/Scheduled/move_tomorrow_to_today.py`

**AC Mapping:** "Move Tomorrow → Today" daily 8:00 AM (research_note.md AC #7); graceful handling of missing board/list (AC #12)
**Files to change:**

- `src/planka_tools/jobs/Scheduled/move_tomorrow_to_today.py` — new file

**Steps:**

1. Implement:
   ```python
   """Move all cards from 'Tomorrow' to 'Today' on Daily Workflow, daily at 8:00 AM."""
   import logging
   from planka_tools.api.client import PlankaClient

   log = logging.getLogger(__name__)

   TRIGGER = {"type": "cron", "hour": 8, "minute": 0}

   def run(client: PlankaClient) -> None:
       project = client.find_project("Trello Import")
       if not project:
           log.warning("Project 'Trello Import' not found — skipping")
           return
       board = client.find_board(project["id"], "Daily Workflow")
       if not board:
           log.warning("Board 'Daily Workflow' not found — skipping")
           return
       src_list = client.find_list(board["id"], "Tomorrow")
       dst_list = client.find_list(board["id"], "Today")
       if not src_list or not dst_list:
           log.warning("List 'Tomorrow' or 'Today' not found on board — skipping")
           return
       cards = [c for c in client.get_cards(board["id"]) if c.get("listId") == src_list["id"]]
       for card in cards:
           client.move_card(card["id"], dst_list["id"])
       log.info("Moved %d card(s) from Tomorrow to Today", len(cards))
   ```
2. Confirm `find_project`/`find_board`/`find_list` signatures against `client.py:356-368` before finalizing (names/args must match exactly).

**Testing:**

- Covered by Subtask 16 (`tests/test_jobs_scheduled.py`).

---

### Subtask 10: Implement `jobs/Scheduled/move_this_month_to_this_week.py`

**AC Mapping:** "Move This Month → This Week" 1st-of-month 4:00 AM (AC #8); graceful missing-list handling (AC #12)
**Files to change:**

- `src/planka_tools/jobs/Scheduled/move_this_month_to_this_week.py` — new file

**Steps:**

1. Same structure as Subtask 9, with `TRIGGER = {"type": "cron", "day": 1, "hour": 4, "minute": 0}`, source list `"This Month"`, destination list `"This Week"`, same board/project.

**Testing:**

- Covered by Subtask 16.

---

### Subtask 11: Implement `jobs/Scheduled/sweep_past_due.py`

**AC Mapping:** "Past-Due" sweep, daily 11:59 PM (AC #9); due-date timezone handling (analysis Risks section)
**Files to change:**

- `src/planka_tools/jobs/Scheduled/sweep_past_due.py` — new file

**Steps:**

1. Implement using `datetime.fromisoformat` with UTC normalization per the analysis's Risks note:
   ```python
   """Move cards with a past due date to 'Past-Due' on Daily Workflow, daily at 23:59."""
   import logging
   from datetime import datetime, timezone
   from planka_tools.api.client import PlankaClient

   log = logging.getLogger(__name__)

   TRIGGER = {"type": "cron", "hour": 23, "minute": 59}

   def _is_past_due(due_date_str: str, now: datetime) -> bool:
       due = datetime.fromisoformat(due_date_str.replace("Z", "+00:00"))
       if due.tzinfo is None:
           due = due.replace(tzinfo=timezone.utc)
       return due < now

   def run(client: PlankaClient) -> None:
       project = client.find_project("Trello Import")
       if not project:
           log.warning("Project 'Trello Import' not found — skipping")
           return
       board = client.find_board(project["id"], "Daily Workflow")
       if not board:
           log.warning("Board 'Daily Workflow' not found — skipping")
           return
       dst_list = client.find_list(board["id"], "Past-Due")
       if not dst_list:
           log.warning("List 'Past-Due' not found — skipping")
           return
       now = datetime.now(timezone.utc)
       cards = client.get_cards(board["id"])
       moved = 0
       for card in cards:
           due = card.get("dueDate")
           if due and card.get("listId") != dst_list["id"] and _is_past_due(due, now):
               client.move_card(card["id"], dst_list["id"])
               moved += 1
       log.info("Swept %d overdue card(s) to Past-Due", moved)
   ```
2. Guard against re-moving cards already in Past-Due (the `card.get("listId") != dst_list["id"]` check above) to avoid needless API calls on every nightly run.

**Testing:**

- Covered by Subtask 16, including a case for a card already in Past-Due (no-op) and a card with no `dueDate` (skipped).

---

### Subtask 12: Implement `jobs/Scheduled/copy_daily_to_today.py`

**AC Mapping:** "Copy Daily → Today" daily 6:00 AM (AC #10); `duplicate_card` + `move_card` pattern (analysis Risks section, `tests/test_card_copy.py`)
**Files to change:**

- `src/planka_tools/jobs/Scheduled/copy_daily_to_today.py` — new file

**Steps:**

1. Implement, resolving the source board/project as "Personal" and destination as "Daily Workflow" (two different boards, confirm both belong to project "Trello Import" per the issue's example wording — re-check `Planka Job System.md` example 4 wording if ambiguous):
   ```python
   """Copy each card in 'Daily' (Personal board) to 'Today' (Daily Workflow board), daily at 6:00 AM."""
   import logging
   from planka_tools.api.client import PlankaClient

   log = logging.getLogger(__name__)

   TRIGGER = {"type": "cron", "hour": 6, "minute": 0}

   def run(client: PlankaClient) -> None:
       project = client.find_project("Trello Import")
       if not project:
           log.warning("Project 'Trello Import' not found — skipping")
           return
       src_board = client.find_board(project["id"], "Personal")
       dst_board = client.find_board(project["id"], "Daily Workflow")
       if not src_board or not dst_board:
           log.warning("Source or destination board not found — skipping")
           return
       src_list = client.find_list(src_board["id"], "Daily")
       dst_list = client.find_list(dst_board["id"], "Today")
       if not src_list or not dst_list:
           log.warning("List 'Daily' or 'Today' not found — skipping")
           return
       cards = [c for c in client.get_cards(src_board["id"]) if c.get("listId") == src_list["id"]]
       for card in cards:
           copy = client.duplicate_card(card["id"])
           client.move_card(copy["id"], dst_list["id"])
       log.info("Copied %d card(s) from Daily to Today", len(cards))
   ```
2. Read `tests/test_card_copy.py` (if present) before finalizing to confirm `duplicate_card`'s return shape includes `"id"` directly (not nested under `"item"` again — check `client.py:233-236`).

**Testing:**

- Covered by Subtask 16.

---

### Subtask 13: Implement `jobs/Webhook/auto_assign_in_progress.py`

**AC Mapping:** "Auto-assign on In-Progress" webhook job (AC #11); depends on Subtask 1 (`add_member_to_card`)
**Files to change:**

- `src/planka_tools/jobs/Webhook/auto_assign_in_progress.py` — new file

**Steps:**

1. Implement using the same `prevData`/`data` list-move detection pattern already established in `webhook/handlers.py:45-52` (`_is_card_list_move`):
   ```python
   """Assign AUTO_ASSIGN_USER_ID when a card moves to 'In-Progress' on Daily Workflow."""
   import logging
   import os
   from planka_tools.api.client import PlankaClient

   log = logging.getLogger(__name__)

   EVENTS = ["cardUpdate"]

   def run(event: str, payload: dict, client: PlankaClient) -> None:
       user_id = os.environ.get("AUTO_ASSIGN_USER_ID")
       if not user_id:
           log.warning("AUTO_ASSIGN_USER_ID not set — skipping auto-assign")
           return
       try:
           old_list_id = payload["prevData"]["item"]["listId"]
           new_list_id = payload["data"]["item"]["listId"]
           card_id = payload["data"]["item"]["id"]
           board_id = payload["data"]["item"]["boardId"]
       except (KeyError, TypeError):
           return
       if old_list_id == new_list_id:
           return
       project = client.find_project("Trello Import")
       board = client.find_board(project["id"], "Daily Workflow") if project else None
       if not board or board["id"] != board_id:
           return
       target_list = client.find_list(board["id"], "In-Progress")
       if not target_list or target_list["id"] != new_list_id:
           return
       client.add_member_to_card(card_id, user_id)
       log.info("Assigned user %s to card %s (moved to In-Progress)", user_id, card_id)
   ```

**Testing:**

- Covered by Subtask 17 (`tests/test_jobs_webhook.py`).

---

### Subtask 14: Update `scheduler/commands.py` `list_jobs`

**AC Mapping:** Operational visibility for discovered jobs (supports AC #5, no dedicated AC but required by Proposed Subtasks)
**Files to change:**

- `src/planka_tools/scheduler/commands.py` — extend `list_jobs()` (lines 13-30)

**Steps:**

1. `build_scheduler()` (after Subtask 7's change) already registers discovered jobs onto the same `scheduler` object returned to `list_jobs`, and `scheduler.get_jobs()` (line 29) already iterates **all** registered jobs — so discovered jobs with `jobs_` prefixed IDs will already appear in the existing loop with no code change required, *provided* Subtask 7 registers them even when `board_ids` is empty (see Subtask 7 step 5's note about the early return).
2. To make output clearer, optionally split the printed list by ID prefix:
   ```python
   typer.echo(f"  Jobs     :")
   for job in scheduler.get_jobs():
       kind = "discovered" if job.id.startswith("jobs_") else "board-sync"
       typer.echo(f"    • [{kind}] {job.name}")
   ```
   replacing the existing `for job in scheduler.get_jobs(): typer.echo(f"    • {job.name}")` loop (line 29-30).
3. Also handle the case where `board_ids` is empty but discovered jobs exist — currently `list_jobs()` returns early at line 20-22 (`if not board_ids: ... return`) before reaching the job-listing loop. Remove/adjust this early return so discovered jobs still print even with no `PLANKA_AUTOMATION_BOARDS` configured.

**Testing:**

- Manual: run `pt scheduler list` with `PLANKA_AUTOMATION_BOARDS` unset and at least one job script present; confirm discovered job(s) print instead of the "No boards configured" message.

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

---

### Subtask 16: Write `tests/test_jobs_scheduled.py`

**AC Mapping:** AC #7, #8, #9, #10 (four scheduled job behaviors), AC #12 (missing board/list handling)
**Files to change:**

- `tests/test_jobs_scheduled.py` — new file

**Steps:**

1. For each of the four job modules (Subtasks 9-12), construct a `MagicMock()` for `PlankaClient` (no need for the `_patch_client()` CLI-context-manager pattern from `test_card_move.py` since jobs take `client` as a direct function argument — call `module.run(mock_client)` directly).
2. Per job, assert:
   - Correct `find_project`/`find_board`/`find_list` calls with expected name arguments.
   - Correct `move_card`/`duplicate_card` calls for each qualifying card.
   - When `find_project`/`find_board`/`find_list` returns `None`, `run()` returns early and does not call `move_card`/`get_cards`.
3. For `sweep_past_due`, add cases: card with future `dueDate` (not moved), card with past `dueDate` already in Past-Due list (not re-moved), card with no `dueDate` (skipped).

**Testing:**

- This file *is* the test; run via `pytest tests/test_jobs_scheduled.py -v`.

---

### Subtask 17: Write `tests/test_jobs_webhook.py`

**AC Mapping:** AC #11 (auto-assign), AC #13 (deleted card/list handling)
**Files to change:**

- `tests/test_jobs_webhook.py` — new file

**Steps:**

1. Mock `PlankaClient`, set `AUTO_ASSIGN_USER_ID` env var via `monkeypatch.setenv`.
2. Cases:
   - Card moved to "In-Progress" on the correct board → `add_member_to_card` called once with correct `card_id`/`user_id`.
   - Card moved to a different list → `add_member_to_card` not called.
   - `prevData` missing (e.g., `cardCreate`-shaped payload without `prevData`) → handled gracefully, no exception, no call.
   - `find_project`/`find_board`/`find_list` returns `None` (deleted board/list) → no call, no exception.
   - `AUTO_ASSIGN_USER_ID` unset → `run()` returns early, no call.

**Testing:**

- This file *is* the test; run via `pytest tests/test_jobs_webhook.py -v`.

---

### Subtask 18: Write `tests/test_webhook_handlers_jobs.py`

**AC Mapping:** AC #3, #4 (webhook job dispatch), AC #15 (one failing job doesn't block others/existing automation)
**Files to change:**

- `tests/test_webhook_handlers_jobs.py` — new file

**Steps:**

1. Patch `planka_tools.webhook.handlers.loader.load_webhook_jobs` to return a list of `MagicMock` modules with controllable `EVENTS` and `run` attributes (mirrors patching style from `test_card_move.py`, applied to `webhook.handlers` instead of `card.commands`).
2. Cases:
   - Discovered job's `EVENTS` includes the incoming event → its `run(event, payload, client)` is called once.
   - Discovered job's `EVENTS` does not include the event → `run` not called.
   - Discovered job's `run` raises an exception → `handle_event` does not propagate it, and (if a second job is also discovered) the second job's `run` is still called.
   - Existing `sync_list_point_totals` behavior for `cardUpdate`/`cardDelete`/`customFieldValueUpdate` is unaffected by the presence of discovered jobs (regression check against Subtask 8's placement of the new dispatch loop).

**Testing:**

- This file *is* the test; run via `pytest tests/test_webhook_handlers_jobs.py -v`.

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

---

## Next Steps

- [ ] Confirm the `add_member_to_card` endpoint correction (Subtask 1) with a live smoke test before implementing Subtask 13
- [ ] Implement subtasks in the order listed — client method → package scaffold → loader → runner/handler integration → example jobs → CLI → tests → docs
