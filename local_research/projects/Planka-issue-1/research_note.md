# Research Note — Issue #1: P-0001 Scheduled and Webhook-Driven Job System for Planka Tools

**Issue URL:** https://github.com/Dante4109/Planka/issues/1
**Date Started:** 2026-07-20
**Status:** OPEN
**Author:** RJ Zeller (Dante4109)
**Assignees:** None
**Labels:** None
**Milestone:** None

---

## Issue Summary

Create a job automation system for Planka Tools that supports two trigger types: time-based schedules (via APScheduler) and webhook-driven events (card create/move/update/delete). The system should allow any method in `client.py` to be callable from job scripts, with each job isolated to its own file and organized into `Scheduled` and `Webhook` folders. The system must auto-discover new jobs without requiring core changes.

## Acceptance Criteria

- [ ] APScheduler-style time trigger fires correctly (daily at time, specific weekday, every X hours)
- [ ] Scheduled job's action script executes and calls `client.py` method(s) successfully
- [ ] Webhook event (card created/moved/updated/deleted) triggers matching webhook job
- [ ] Webhook job executes action upon receiving webhook sidecar event
- [ ] New job script added to `Scheduled`/`Webhook` folder is auto-discovered and registered on system start/reload
- [ ] Job script calling `client.py` method reflects resulting state change in Planka
- [ ] "Move Tomorrow → Today" scheduled job (daily 8:00 AM) moves all cards from "Tomorrow" to "Today" on Daily Workflow board
- [ ] "Move This Month → This Week" scheduled job (1st of month, 4:00 AM) moves cards from "This Month" to "This Week" on Daily Workflow board
- [ ] "Past-Due" scheduled job (daily 11:59 PM) moves overdue cards to "Past-Due" list on Daily Workflow board
- [ ] "Copy Daily → Today" scheduled job (daily 6:00 AM) copies cards from Daily (Personal board) to Today (Daily Workflow board)
- [ ] "Auto-assign on In-Progress" webhook job assigns configured user when card moves to "In-Progress" on Daily Workflow board
- [ ] System handles missing/renamed list/board/project gracefully (log error, skip job)
- [ ] Webhook event referencing deleted card/list/board handled gracefully (log error, skip action)
- [ ] Overlapping/duplicate trigger fires (scheduler restart) handled without duplicate actions or crashes
- [ ] `client.py` method call failure (network/API/auth) logged gracefully; runner continues
- [ ] Concurrent job actions on same card handled safely (no race conditions)
- [ ] Malformed or missing job definition file handled gracefully (log error, skip)

## Key Files / Areas of Codebase

- `src/planka_tools/api/client.py` — core API methods to be called by job scripts
- `src/planka_tools/` — main package directory (job system likely to be added here)
- Existing webhook sidecar (referenced in issue; location TBD — needs investigation)
- `notes/automation ideas/To-Do/Planka Job System.md` — source user story

**Inferred new module structure (to be created):**
- `src/planka_tools/jobs/` — root jobs module
  - `src/planka_tools/jobs/scheduler.py` — APScheduler integration and runner
  - `src/planka_tools/jobs/webhook_handler.py` — webhook event dispatcher
  - `src/planka_tools/jobs/Scheduled/` — directory for time-triggered job scripts
  - `src/planka_tools/jobs/Webhook/` — directory for event-triggered job scripts
  - `src/planka_tools/jobs/examples/` — example job scripts for reference

## Open Questions

1. **Existing webhook sidecar location:** Where is the existing webhook sidecar code? How does it currently work? What event format does it send?
2. **Job file format:** Should job scripts be Python modules with a standard interface (e.g., a `run()` function)? How do we define triggers (APScheduler config, metadata in file, separate config file)?
3. **Configuration storage:** Where should job trigger definitions live? In the job file itself (as decorators/config constants) or in a centralized config file?
4. **Job persistence/state:** Should executed jobs be logged/tracked? Should there be a job history or audit trail?
5. **Environment and imports:** How should job scripts access `client` and other dependencies? Should there be a job execution context or DI pattern?
6. **Testing strategy:** How should jobs be tested? Should there be mock webhook events and scheduled job runners for unit/integration tests?
7. **Error retry logic:** Should failed jobs auto-retry? If so, with what backoff strategy?
8. **Concurrency and locking:** How should we handle concurrent job execution (e.g., two jobs modifying the same card)? Do we need distributed locking or simple in-process locks?
9. **Job monitoring/observability:** Should there be logging, metrics, or alerting for job execution (success/failure/duration)?
10. **Webhook signature verification:** Should webhook events be signed/verified for security?

## Additional Context / Notes

- **Source story:** Captured from `notes/automation ideas/To-Do/Planka Job System.md`
- **User story provided:** Full BDD-style acceptance criteria already defined in issue body
- **Real-world job examples included:** Four APScheduler examples (Move Tomorrow, Move This Month, Past-Due, Copy Daily) and one webhook example (Auto-assign on In-Progress) are defined and ready for implementation
- **API surface clear:** All job actions invoke `client.py` methods, so the API boundary is well-defined
- **Modular job storage:** Folder-based organization (`Scheduled`/`Webhook`) suggests a plugin-like auto-discovery pattern

## Branch

**Branch:** `feature/issue-1-job-system` (newly created and active)

**Status:** Checked out and ready for development
**Commit History:** No commits on this branch yet (branched from main)

**Branch naming:** Follows pattern `feature/issue-<NUMBER>-<short-slug>`
