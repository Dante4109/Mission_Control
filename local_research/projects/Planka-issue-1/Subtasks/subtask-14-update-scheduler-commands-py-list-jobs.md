# Planka-issue-1 -- Subtask 14: Update `scheduler/commands.py` `list_jobs`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

---

### Subtask 14: Update `scheduler/commands.py` `list_jobs`

**AC Mapping:** Operational visibility for discovered jobs (supports AC #5, no dedicated AC but required by Proposed Subtasks)
**Files to change:**

- `src/planka_tools/scheduler/commands.py` — extend `list_jobs()` (lines 13-30)

**Steps:**

1. `build_scheduler()` (after Subtask 7's change) already registers discovered jobs onto the same `scheduler` object returned to `list_jobs`, and `scheduler.get_jobs()` (line 29) already iterates **all** registered jobs — so discovered jobs with `jobs_` prefixed IDs will already appear in the existing loop with no code change required, *provided* Subtask 7 registers them even when `board_ids` is empty (see Subtask 7 step 5's note about the early return).
2. To make output clearer, optionally split the printed list by ID prefix:
   ```python
   typer.echo(f"  Jobs     :")
   for job in scheduler.get_jobs():
       kind = "discovered" if job.id.startswith("jobs_") else "board-sync"
       typer.echo(f"    • [{kind}] {job.name}")
   ```
   replacing the existing `for job in scheduler.get_jobs(): typer.echo(f"    • {job.name}")` loop (line 29-30).
3. Also handle the case where `board_ids` is empty but discovered jobs exist — currently `list_jobs()` returns early at line 20-22 (`if not board_ids: ... return`) before reaching the job-listing loop. Remove/adjust this early return so discovered jobs still print even with no `PLANKA_AUTOMATION_BOARDS` configured.

**Testing:**

- Manual: run `pt scheduler list` with `PLANKA_AUTOMATION_BOARDS` unset and at least one job script present; confirm discovered job(s) print instead of the "No boards configured" message.

