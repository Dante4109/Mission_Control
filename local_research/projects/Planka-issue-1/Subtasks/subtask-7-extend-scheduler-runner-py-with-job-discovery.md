# Planka-issue-1 -- Subtask 7: Extend `scheduler/runner.py` with job discovery

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

---

### Subtask 7: Extend `scheduler/runner.py` with job discovery

**AC Mapping:** APScheduler CronTrigger firing (AC #1), scheduled job execution (AC #2), auto-discovery (AC #5), no-duplicate-fire handling (AC #14, #16)
**Files to change:**

- `src/planka_tools/scheduler/runner.py` — extend `build_scheduler()` (lines 67-90)

**Steps:**

1. Add imports: `from apscheduler.triggers.cron import CronTrigger`, `from planka_tools.jobs import loader`, `from planka_tools.api.client import PlankaClient` (already imported), `import os` for `JOBS_DIR` (`os` already imported).
2. Add a `_jobs_dir()` helper mirroring `_load_env` style:
   ```python
   def _jobs_dir() -> Path:
       override = _load_env("JOBS_DIR")
       base = Path(override) if override else Path(__file__).resolve().parents[1] / "jobs"
       return base
   ```
3. Add `_make_scheduled_job_runner(module)` that wraps a discovered job's `run(client)` in the same try/except pattern as `_make_job` (lines 46-64):
   ```python
   def _make_scheduled_job_runner(module):
       def job():
           log.info("Running discovered job '%s' ...", module.__name__)
           try:
               with PlankaClient() as client:
                   module.run(client)
           except PlankaError as e:
               log.error("API error in job %s: %s", module.__name__, e)
           except Exception as e:
               log.error("Unexpected error in job %s: %s", module.__name__, e)
       job.__name__ = f"jobs_{module.__name__}"
       return job
   ```
4. Add `load_and_register_jobs(scheduler, jobs_dir)`:
   ```python
   def load_and_register_jobs(scheduler: BlockingScheduler, jobs_dir: Path) -> list[str]:
       registered = []
       for module in loader.load_scheduled_jobs(jobs_dir / "Scheduled"):
           trig = dict(module.TRIGGER)
           trig_type = trig.pop("type", "cron")
           trigger = CronTrigger(**trig) if trig_type == "cron" else IntervalTrigger(**trig)
           job_id = f"jobs_{module.__name__}"
           scheduler.add_job(
               _make_scheduled_job_runner(module),
               trigger=trigger,
               id=job_id,
               name=module.__name__,
               max_instances=1,
               coalesce=True,
           )
           registered.append(job_id)
       return registered
   ```
   Note the `jobs_` prefix on job IDs, per the analysis's risk note on ID collisions with `sync_points_{board_id}`.
5. Call `load_and_register_jobs(scheduler, _jobs_dir())` at the end of `build_scheduler()` (line 90), **unconditionally** — do not gate it behind `if not board_ids` (line 72-73 currently returns early with an empty scheduler when no boards are configured; discovered jobs should still register in that case). Restructure so the early return at lines 72-73 also calls `load_and_register_jobs` before returning.

**Testing:**

- Manual: `pt scheduler run` with at least one job script present in `jobs/Scheduled/`, confirm log line "Running discovered job ..." appears at trigger time (or verify via `scheduler.get_jobs()` in a REPL without starting the blocking loop).
- Unit coverage of the trigger-mapping and registration logic via `tests/test_jobs_scheduled.py` is out of scope for this subtask (that file mocks at the job level, not the runner level) — no dedicated runner unit test is listed in Proposed Subtasks; verify manually per above.

