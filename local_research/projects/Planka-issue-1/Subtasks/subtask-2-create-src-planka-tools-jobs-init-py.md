# Planka-issue-1 -- Subtask 2: Create `src/planka_tools/jobs/__init__.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

---

### Subtask 2: Create `src/planka_tools/jobs/__init__.py`

**AC Mapping:** Foundational — enables job package structure (supports AC #5, auto-discovery)
**Files to change:**

- `src/planka_tools/jobs/__init__.py` — new, empty file

**Steps:**

1. Create empty `__init__.py` to mark `jobs` as a regular package (matches style of other `planka_tools` subpackages — no `__all__`, no re-exports).

**Testing:**

- Import check: `python -c "import planka_tools.jobs"` succeeds with no error.

