# Planka-issue-1 -- Subtask 11: Implement `jobs/Scheduled/sweep_past_due.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

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

