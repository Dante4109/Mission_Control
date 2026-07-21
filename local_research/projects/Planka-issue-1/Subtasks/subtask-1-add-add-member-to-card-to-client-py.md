# Planka-issue-1 -- Subtask 1: Add `add_member_to_card` to `client.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

---

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

