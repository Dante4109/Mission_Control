# Planka-issue-1 -- Subtask 17: Write `tests/test_jobs_webhook.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

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

