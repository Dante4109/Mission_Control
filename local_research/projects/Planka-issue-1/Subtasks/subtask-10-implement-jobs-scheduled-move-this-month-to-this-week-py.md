# Planka-issue-1 -- Subtask 10: Implement `jobs/Scheduled/move_this_month_to_this_week.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

---

### Subtask 10: Implement `jobs/Scheduled/move_this_month_to_this_week.py`

**AC Mapping:** "Move This Month → This Week" 1st-of-month 4:00 AM (AC #8); graceful missing-list handling (AC #12)
**Files to change:**

- `src/planka_tools/jobs/Scheduled/move_this_month_to_this_week.py` — new file

**Steps:**

1. Same structure as Subtask 9, with `TRIGGER = {"type": "cron", "day": 1, "hour": 4, "minute": 0}`, source list `"This Month"`, destination list `"This Week"`, same board/project.

**Testing:**

- Covered by Subtask 16.

