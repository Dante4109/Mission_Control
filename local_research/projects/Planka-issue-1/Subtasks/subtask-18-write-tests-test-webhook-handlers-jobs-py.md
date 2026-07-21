# Planka-issue-1 -- Subtask 18: Write `tests/test_webhook_handlers_jobs.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

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

