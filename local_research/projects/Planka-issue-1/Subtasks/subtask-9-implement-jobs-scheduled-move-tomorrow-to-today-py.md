# Planka-issue-1 -- Subtask 9: Implement `jobs/Scheduled/move_tomorrow_to_today.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

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

