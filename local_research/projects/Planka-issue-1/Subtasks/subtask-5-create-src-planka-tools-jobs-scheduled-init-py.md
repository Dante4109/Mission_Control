# Planka-issue-1 -- Subtask 5: Create `src/planka_tools/jobs/Scheduled/__init__.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

---

### Subtask 5: Create `src/planka_tools/jobs/Scheduled/__init__.py`

**AC Mapping:** Supports directory-based job discovery (AC #5)
**Files to change:**

- `src/planka_tools/jobs/Scheduled/__init__.py` — new, empty file

**Steps:**

1. Create empty file so `Scheduled/` is a regular package directory (loader iterates `*.py` in it via `Path.glob`, but an `__init__.py` keeps it importable/consistent with the rest of the codebase and lets `loader._load_jobs` skip it by name).

**Testing:**

- Import check: `python -c "import planka_tools.jobs.Scheduled"` succeeds.

