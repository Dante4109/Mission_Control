# Planka-issue-1 -- Subtask 13: Implement `jobs/Webhook/auto_assign_in_progress.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

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

