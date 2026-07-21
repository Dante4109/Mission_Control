# Planka-issue-1 — Subtasks Index

**Date:** 2026-07-20
**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

| # | Subtask | File | AC Mapping |
|---|---------|------|------------|
| 1 | Add `add_member_to_card` to `client.py` | [subtask-1-add-add-member-to-card-to-client-py.md](./subtask-1-add-add-member-to-card-to-client-py.md) | Auto-assign job (AC #11); corrects endpoint to `/api/cards/{card_id}/members` |
| 2 | Create `src/planka_tools/jobs/__init__.py` | [subtask-2-create-src-planka-tools-jobs-init-py.md](./subtask-2-create-src-planka-tools-jobs-init-py.md) | Foundational package structure |
| 3 | Create `src/planka_tools/jobs/base.py` | [subtask-3-create-src-planka-tools-jobs-base-py.md](./subtask-3-create-src-planka-tools-jobs-base-py.md) | Job contract documentation |
| 4 | Create `src/planka_tools/jobs/loader.py` | [subtask-4-create-src-planka-tools-jobs-loader-py.md](./subtask-4-create-src-planka-tools-jobs-loader-py.md) | Auto-discovery (AC #5), malformed job handling (AC #16) |
| 5 | Create `src/planka_tools/jobs/Scheduled/__init__.py` | [subtask-5-create-src-planka-tools-jobs-scheduled-init-py.md](./subtask-5-create-src-planka-tools-jobs-scheduled-init-py.md) | Supports discovery (AC #5) |
| 6 | Create `src/planka_tools/jobs/Webhook/__init__.py` | [subtask-6-create-src-planka-tools-jobs-webhook-init-py.md](./subtask-6-create-src-planka-tools-jobs-webhook-init-py.md) | Supports discovery (AC #5) |
| 7 | Extend `scheduler/runner.py` with job discovery | [subtask-7-extend-scheduler-runner-py-with-job-discovery.md](./subtask-7-extend-scheduler-runner-py-with-job-discovery.md) | CronTrigger firing (AC #1, #2), discovery (AC #5), no-dup-fire (AC #14, #16) |
| 8 | Extend `webhook/handlers.py` with job dispatch | [subtask-8-extend-webhook-handlers-py-with-job-dispatch.md](./subtask-8-extend-webhook-handlers-py-with-job-dispatch.md) | Webhook dispatch (AC #3, #4), missing-data handling (AC #13), failure isolation (AC #15) |
| 9 | Implement `jobs/Scheduled/move_tomorrow_to_today.py` | [subtask-9-implement-jobs-scheduled-move-tomorrow-to-today-py.md](./subtask-9-implement-jobs-scheduled-move-tomorrow-to-today-py.md) | AC #7 |
| 10 | Implement `jobs/Scheduled/move_this_month_to_this_week.py` | [subtask-10-implement-jobs-scheduled-move-this-month-to-this-week-py.md](./subtask-10-implement-jobs-scheduled-move-this-month-to-this-week-py.md) | AC #8 |
| 11 | Implement `jobs/Scheduled/sweep_past_due.py` | [subtask-11-implement-jobs-scheduled-sweep-past-due-py.md](./subtask-11-implement-jobs-scheduled-sweep-past-due-py.md) | AC #9 |
| 12 | Implement `jobs/Scheduled/copy_daily_to_today.py` | [subtask-12-implement-jobs-scheduled-copy-daily-to-today-py.md](./subtask-12-implement-jobs-scheduled-copy-daily-to-today-py.md) | AC #10 |
| 13 | Implement `jobs/Webhook/auto_assign_in_progress.py` | [subtask-13-implement-jobs-webhook-auto-assign-in-progress-py.md](./subtask-13-implement-jobs-webhook-auto-assign-in-progress-py.md) | AC #11 (depends on Subtask 1) |
| 14 | Update `scheduler/commands.py` `list_jobs` | [subtask-14-update-scheduler-commands-py-list-jobs.md](./subtask-14-update-scheduler-commands-py-list-jobs.md) | Operational visibility for discovered jobs |
| 15 | Write `tests/test_job_loader.py` | [subtask-15-write-tests-test-job-loader-py.md](./subtask-15-write-tests-test-job-loader-py.md) | AC #5, #16 |
| 16 | Write `tests/test_jobs_scheduled.py` | [subtask-16-write-tests-test-jobs-scheduled-py.md](./subtask-16-write-tests-test-jobs-scheduled-py.md) | AC #7, #8, #9, #10, #12 |
| 17 | Write `tests/test_jobs_webhook.py` | [subtask-17-write-tests-test-jobs-webhook-py.md](./subtask-17-write-tests-test-jobs-webhook-py.md) | AC #11, #13 |
| 18 | Write `tests/test_webhook_handlers_jobs.py` | [subtask-18-write-tests-test-webhook-handlers-jobs-py.md](./subtask-18-write-tests-test-webhook-handlers-jobs-py.md) | AC #3, #4, #15 |
| 19 | Update `COMMANDS.md` | [subtask-19-update-commands-md.md](./subtask-19-update-commands-md.md) | Documentation completeness |
