P-0001 — Scheduled and Webhook-Driven Job System for Planka Tools
Analysis:
Extend the existing scheduler and webhook subsystems with a plugin-style auto-discovery layer that loads isolated job scripts from `Scheduled/` and `Webhook/` directories, registers them with APScheduler (cron triggers) and the Flask webhook dispatcher respectively, and ships five concrete example jobs covering the acceptance criteria.

**Date:** 2026-07-20
**Author:** RJ Zeller (Dante4109)
**GH Issue Link:** https://github.com/Dante4109/Planka/issues/1
**GH Issue Labels:** None
**Affected Systems:** `planka_tools.scheduler`, `planka_tools.webhook`, `planka_tools.api.client`, CLI (`pt scheduler`, `pt webhook`)
**Target Surface:** `src/planka_tools/jobs/` (new package), `src/planka_tools/scheduler/runner.py`, `src/planka_tools/webhook/handlers.py`, `src/planka_tools/api/client.py`

---

## Acceptance Criteria

- [ ] APScheduler CronTrigger fires correctly for daily-at-time, first-of-month, and every-X-hours patterns
- [ ] Scheduled job action script executes and calls `client.py` method(s) successfully
- [ ] Webhook event (cardCreate/cardUpdate-list-move/cardDelete) triggers matching webhook job
- [ ] Webhook job executes action upon receiving event from the Flask webhook sidecar
- [ ] New job script added to `Scheduled/` or `Webhook/` is auto-discovered and registered on system start without core changes
- [ ] Job calling `client.py` method reflects resulting state change in Planka
- [ ] "Move Tomorrow → Today" (daily 8:00 AM) moves all cards from "Tomorrow" to "Today" on Daily Workflow board
- [ ] "Move This Month → This Week" (1st of month 4:00 AM) moves cards from "This Month" to "This Week" on Daily Workflow board
- [ ] "Past-Due" (daily 11:59 PM) moves all cards with a past due date to "Past-Due" list on Daily Workflow board
- [ ] "Copy Daily → Today" (daily 6:00 AM) copies each card from "Daily" on Personal board to "Today" on Daily Workflow board
- [ ] "Auto-assign on In-Progress" webhook job assigns configured user when a card is moved to "In-Progress" on Daily Workflow board
- [ ] Missing or renamed list/board/project handled gracefully (log warning, skip job)
- [ ] Webhook event referencing deleted card/list/board handled gracefully (log warning, skip action)
- [ ] Overlapping/duplicate scheduler trigger fires handled without duplicate actions (APScheduler `coalesce=True`, `max_instances=1`)
- [ ] `client.py` method failure (network/API/auth) caught, logged, runner continues
- [ ] Concurrent job actions on same card handled safely (APScheduler `max_instances=1` per job)
- [ ] Malformed or missing job definition file skipped with a log error; system continues loading other jobs

> Unclear/implicit items: The issue does not specify how the job system should be invoked from the CLI beyond the existing `pt scheduler run` entry point; whether job-level retry logic is required; or whether a job history/audit log is required for this phase.

---

## Overview

Build a plugin-style job discovery layer (`src/planka_tools/jobs/`) that extends the existing APScheduler runner and Flask webhook dispatcher to auto-load isolated job scripts from `Scheduled/` and `Webhook/` directories, register them with cron triggers, and ship five concrete example jobs.

---

## Scope

**In Scope:**
- New `src/planka_tools/jobs/` package: `__init__.py`, `base.py` (contract docs), `loader.py` (discovery/import logic)
- `src/planka_tools/jobs/Scheduled/` directory with `__init__.py` and four example job scripts
- `src/planka_tools/jobs/Webhook/` directory with `__init__.py` and one example job script
- Adding `add_member_to_card(card_id, user_id)` to `client.py` (required by auto-assign webhook job)
- Extending `scheduler/runner.py` to discover and register jobs from the job directories using `CronTrigger`
- Extending `webhook/handlers.py` to dispatch to discovered webhook job scripts by event type
- Updating `scheduler/commands.py list` to include discovered jobs in its output
- Unit tests for loader, example jobs, and extended dispatcher/runner
- COMMANDS.md update documenting the job contract and how to add new jobs

**Out of Scope:**
- Persistent job history / audit log
- Job retry / backoff logic
- Distributed locking across multiple running instances
- Webhook signature verification (HMAC) — existing token auth is sufficient for this phase
- A dedicated `pt jobs` CLI subgroup (extend existing `pt scheduler` for now)
- Changing the existing `sync_list_point_totals` automation or its scheduler/webhook hooks

---

## Requirements

- Every job script must expose a module-level `TRIGGER` dict (for Scheduled) or `EVENTS` list (for Webhook) and a `run()` function — no other interface needed
- `TRIGGER` must include a `type` key (`"cron"` or `"interval"`) plus APScheduler trigger kwargs
- `EVENTS` is a list of Planka event name strings the webhook job subscribes to (e.g., `["cardUpdate"]`)
- `run(client: PlankaClient)` for Scheduled jobs; `run(event: str, payload: dict, client: PlankaClient)` for Webhook jobs
- Loader must catch `ImportError`, `AttributeError`, and any `Exception` during module load; log and skip; never crash the runner
- Scheduler must use `coalesce=True` and `max_instances=1` on all discovered jobs
- Webhook dispatcher must call discovered job `run()` functions only for matching event types; each in a `try/except` so one failing job does not block others
- All board/list/project lookups in job scripts must use the `find_*` convenience helpers on `PlankaClient` and handle `None` returns gracefully (log warning, return early)
- `AUTO_ASSIGN_USER_ID` environment variable used by the auto-assign webhook job
- `JOBS_DIR` environment variable optional override for the base jobs directory (defaults to `src/planka_tools/jobs/`)

---

## Dependencies & Contracts

| Dependency | What the job system needs from it |
|---|---|
| `apscheduler>=3.10.0` | Already installed. Add `CronTrigger` import to `runner.py` |
| `flask>=3.0.0` | Already installed. Webhook dispatcher unchanged; `handlers.py` extended |
| `planka_tools.api.client.PlankaClient` | All existing methods available. New: `add_member_to_card(card_id, user_id)` |
| `planka_tools.api.client.PlankaError` | Imported in job scripts for specific error handling |
| Python `importlib` | Used by `loader.py` to dynamically import job modules by path |
| `.env` / environment | `AUTO_ASSIGN_USER_ID`, `JOBS_DIR` (new); existing credentials unchanged |

**New `client.py` method required:**
```
add_member_to_card(self, card_id: str, user_id: str) -> dict
    POST /api/cards/{card_id}/card-members  body: {"userId": user_id}
```
Pattern follows existing `add_label_to_card` (same API shape, different resource path).

---

## Risks & Constraints

- **Dynamic import security**: `loader.py` imports arbitrary `.py` files from the jobs directories. In this personal-use context the risk is acceptable; document that these directories should contain only trusted scripts.
- **APScheduler job ID collisions**: If `runner.py` is extended naively, job IDs from `sync_points_{board_id}` and job IDs from the discovery system could collide if someone names a job the same way. Use a `jobs_` prefix on discovered job IDs.
- **Webhook dispatcher performance**: The dispatcher is synchronous and Flask is single-threaded by default. Long-running webhook jobs will delay the HTTP 200 response to Planka. For this phase, accept the blocking behavior and note it as a future improvement (async/task queue).
- **`duplicate_card` vs copy-then-move**: The "Copy Daily → Today" job uses `client.duplicate_card(card_id)` followed by `client.move_card(copied_id, target_list_id)` — the same pattern already tested in `tests/test_card_copy.py`. Confirm `duplicate_card` preserves task lists and labels as expected.
- **Due date comparison timezone**: The "Past-Due" job compares `card["dueDate"]` (ISO 8601 string from Planka) against `datetime.utcnow()`. Must parse and compare consistently; use `datetime.fromisoformat` with UTC normalization.
- **`find_card` by board_id fetches all cards**: For the copy-daily job, `client.get_cards(board_id)` fetches all cards and filters in Python. Acceptable at current board size; note as a scaling concern.

---

## Open Questions

1. **`add_member_to_card` API path**: Based on the pattern of `add_label_to_card` (`POST /api/cards/{card_id}/card-labels`), the member endpoint is assumed to be `POST /api/cards/{card_id}/card-members` with body `{"userId": user_id}`. Confirm against Planka API docs or live test before implementing.
2. **Job file location**: Should the `Scheduled/` and `Webhook/` folders live inside the installed package at `src/planka_tools/jobs/` (version-controlled, ship with the package), or in a user-configurable directory outside the package (runtime-configurable via `JOBS_DIR`)? Recommendation: version-controlled for the example jobs, `JOBS_DIR` override for user-added jobs.
3. **`cardCreate` event**: The issue mentions "card created" as a webhook trigger. Planka's actual event name for card creation needs confirmation — check `webhook/handlers.py` event list. Currently only `customFieldValueUpdate`, `customFieldValueDelete`, `cardUpdate`, `cardDelete` are handled. May need to add `cardCreate` to the webhook registration command's `--events` default.
4. **Retry/backoff**: The issue does not require retry logic. Confirm no retry is needed for this phase before closing.
5. **Job history/audit log**: Not required for this phase. Confirm.

---

## Implementation Phases

### Discovery / Design

- Confirm `add_member_to_card` API path against Planka API docs or a live call
- Confirm the Planka event name for card creation (is it `cardCreate`?)
- Decide `JOBS_DIR` default: package-internal vs. configurable external path
- Sketch the `loader.py` module contract with examples; review with stakeholder before writing tests

### Build

1. Add `add_member_to_card` to `client.py`
2. Create `src/planka_tools/jobs/` package (`__init__.py`, `base.py`, `loader.py`)
3. Create `Scheduled/` and `Webhook/` subdirectories with `__init__.py` files
4. Extend `scheduler/runner.py` to call `loader.load_scheduled_jobs()` and register each with a `CronTrigger`
5. Extend `webhook/handlers.py` to call `loader.load_webhook_jobs()` and dispatch matching jobs
6. Implement the four scheduled example jobs
7. Implement the one webhook example job
8. Update `scheduler/commands.py` `list_jobs` to include discovered jobs

### Validate

- Unit tests for `loader.py` (valid module, missing TRIGGER, missing run, import error)
- Unit tests for each of the five example jobs (mock client)
- Unit tests for extended `webhook/handlers.py` dispatch
- Manual smoke test: run `pt scheduler run` and verify discovered jobs are logged; send a test webhook event and verify routing

### Rollout

- Run `Sync-Agents.ps1` in Mission Control if agent definitions change
- No database migrations required
- No Docker image changes required (all dependencies already in `requirements.txt`)
- Confirm `.env` documents `AUTO_ASSIGN_USER_ID` and optional `JOBS_DIR`

---

## Testing Strategy

**Unit Tests:** Mock `PlankaClient` context manager using the existing `_patch_client()` pattern from `test_card_move.py`; test each job's `run()` with pre-set find_*/get_* return values. Test `loader.py` with `importlib` mocks and temp directories.
**Integration Tests:** Not required for this phase; the existing live-Planka tests (manual) are sufficient.
**E2E Tests:** Manual: trigger scheduler and confirm cards move on the real Planka instance; POST a test `cardUpdate` payload to `localhost:5001/webhook` and confirm the auto-assign fires.
**Migration/Backfill:** Not applicable.
**Observability:** All job executions log at INFO level (job name, trigger time, outcome). Failures log at ERROR with traceback. Existing `logging.basicConfig` in `runner.py` and `server.py` covers this.

---

## Logging, Monitoring & Rollback

- All `loader.py` import errors logged at `ERROR` level with file path and exception; system continues
- Each discovered scheduled job logs `INFO` on start and `INFO` or `ERROR` on completion
- Each webhook job dispatch logs `INFO` for the event received and `ERROR` on failure
- Rollback: removing a job file from `Scheduled/` or `Webhook/` and restarting the runner removes it from the schedule — no migration needed
- The existing `sync_list_point_totals` automation is unaffected; it continues to run on its interval trigger

---

## Proposed Subtasks

> Each item below must use markdown checkbox format so downstream agents can parse them.

- [ ] Add `add_member_to_card(card_id: str, user_id: str) -> dict` to `src/planka_tools/api/client.py` using `POST /api/cards/{card_id}/card-members` with body `{"userId": user_id}`, following the `add_label_to_card` pattern
- [ ] Create `src/planka_tools/jobs/__init__.py` (empty, marks as package)
- [ ] Create `src/planka_tools/jobs/base.py` documenting the ScheduledJob contract (`TRIGGER: dict`, `run(client: PlankaClient) -> None`) and WebhookJob contract (`EVENTS: list[str]`, `run(event: str, payload: dict, client: PlankaClient) -> None`) as docstrings with inline examples
- [ ] Create `src/planka_tools/jobs/loader.py` with `load_scheduled_jobs(jobs_dir: Path) -> list[ModuleType]` and `load_webhook_jobs(jobs_dir: Path) -> list[ModuleType]`; each scans the respective subdirectory, imports `.py` files via `importlib`, validates the required attributes exist, logs and skips malformed modules
- [ ] Create `src/planka_tools/jobs/Scheduled/__init__.py` (empty)
- [ ] Create `src/planka_tools/jobs/Webhook/__init__.py` (empty)
- [ ] Extend `src/planka_tools/scheduler/runner.py`: import `CronTrigger` from APScheduler; add `load_and_register_jobs(scheduler, jobs_dir)` function that calls `loader.load_scheduled_jobs()`, maps `TRIGGER["type"]` to `CronTrigger` or `IntervalTrigger`, and adds each job with `coalesce=True`, `max_instances=1`; call it from `build_scheduler()`
- [ ] Extend `src/planka_tools/webhook/handlers.py`: after existing event routing, call `loader.load_webhook_jobs(jobs_dir)`, filter by event type, call each matching job's `run(event, payload, client)` inside a `try/except`; preserve existing `sync_list_point_totals` behavior unchanged
- [ ] Implement `src/planka_tools/jobs/Scheduled/move_tomorrow_to_today.py` with `TRIGGER = {"type": "cron", "hour": 8, "minute": 0}` and `run(client)` that finds project "Trello Import", board "Daily Workflow", resolves list "Tomorrow" and list "Today", and calls `client.move_card()` for each card in Tomorrow
- [ ] Implement `src/planka_tools/jobs/Scheduled/move_this_month_to_this_week.py` with `TRIGGER = {"type": "cron", "day": 1, "hour": 4, "minute": 0}` and `run(client)` that moves all cards from "This Month" to "This Week" on Daily Workflow board
- [ ] Implement `src/planka_tools/jobs/Scheduled/sweep_past_due.py` with `TRIGGER = {"type": "cron", "hour": 23, "minute": 59}` and `run(client)` that fetches all cards on Daily Workflow board, filters those whose `dueDate` is non-null and in the past (UTC), and moves each to "Past-Due" list
- [ ] Implement `src/planka_tools/jobs/Scheduled/copy_daily_to_today.py` with `TRIGGER = {"type": "cron", "hour": 6, "minute": 0}` and `run(client)` that copies each card from "Daily" on "Personal" board to "Today" on "Daily Workflow" board using `client.duplicate_card()` then `client.move_card()`
- [ ] Implement `src/planka_tools/jobs/Webhook/auto_assign_in_progress.py` with `EVENTS = ["cardUpdate"]` and `run(event, payload, client)` that checks if the card moved to a list named "In-Progress" on "Daily Workflow" board (via `prevData`/`data` list ID comparison), then calls `client.add_member_to_card(card_id, AUTO_ASSIGN_USER_ID)` where `AUTO_ASSIGN_USER_ID` is read from the environment
- [ ] Update `src/planka_tools/scheduler/commands.py` `list_jobs` command to also enumerate and display jobs discovered from the `Scheduled/` directory alongside the existing board automation jobs
- [ ] Write `tests/test_job_loader.py`: test valid scheduled job load, valid webhook job load, missing `TRIGGER` skipped with error log, missing `run` skipped with error log, `ImportError` skipped with error log, empty directory returns empty list
- [ ] Write `tests/test_jobs_scheduled.py`: unit test each of the four scheduled job `run()` functions using a mocked `PlankaClient`; assert correct `find_project`/`find_board`/`find_list` calls and correct `move_card`/`duplicate_card` calls; assert graceful return when `find_*` returns `None`
- [ ] Write `tests/test_jobs_webhook.py`: unit test the auto-assign webhook job `run()` with a mocked `PlankaClient`; assert `add_member_to_card` is called when destination list matches "In-Progress"; assert no call when destination list is different; assert graceful handling when card/list lookup fails
- [ ] Write `tests/test_webhook_handlers_jobs.py`: test that `handle_event` dispatches to a discovered webhook job when event matches, skips when event does not match, and catches and logs exceptions from a failing job without re-raising
- [ ] Update `COMMANDS.md` to document the job system: job file contract, `TRIGGER` dict format, `EVENTS` list format, `AUTO_ASSIGN_USER_ID` and `JOBS_DIR` env vars, and how to add a new job

---

## Existing Artifacts

- `C:\projects\AppDev\Mission_Control\local_research\projects\Planka-issue-1\issue_verbatim.md` — raw issue content captured by gh-issue-starter
- `C:\projects\AppDev\Mission_Control\local_research\projects\Planka-issue-1\research_note.md` — structured intake note with 18 ACs, 10 open questions, and initial key files list
- `src/planka_tools/api/client.py` — full PlankaClient; all methods reviewed; `add_member_to_card` is the only missing method needed
- `src/planka_tools/scheduler/runner.py` — existing APScheduler runner using `BlockingScheduler` + `IntervalTrigger`; will be extended with `CronTrigger` and job discovery
- `src/planka_tools/webhook/server.py` — existing Flask server on port 5001 with bearer token auth; no changes required
- `src/planka_tools/webhook/handlers.py` — existing event dispatcher; will be extended to call discovered webhook jobs after existing logic
- `src/planka_tools/automations/list_points.py` — existing `sync_list_point_totals`; unchanged by this issue
- `tests/test_card_move.py` — canonical example of the `_patch_client()` mock pattern used by all existing tests
- `notes/automation ideas/To-Do/Planka Job System.md` — original source story
