# Planka-issue-1 -- Subtask 12: Implement `jobs/Scheduled/copy_daily_to_today.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

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

