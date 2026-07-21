# Planka-issue-1 -- Subtask 16: Write `tests/test_jobs_scheduled.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

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

