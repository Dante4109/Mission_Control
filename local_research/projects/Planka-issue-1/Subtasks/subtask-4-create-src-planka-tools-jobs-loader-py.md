# Planka-issue-1 -- Subtask 4: Create `src/planka_tools/jobs/loader.py`

**GH:** https://github.com/Dante4109/Planka/issues/1
**Plan:** ../implementation_plan.md

---

### Subtask 4: Create `src/planka_tools/jobs/loader.py`

**AC Mapping:** Auto-discovery (AC #5), malformed job handling (AC #16), no-crash isolation (AC #6, #15)
**Files to change:**

- `src/planka_tools/jobs/loader.py` — new file

**Steps:**

1. Implement using `importlib.util.spec_from_file_location` / `module_from_spec` (not package-relative import, since job files aren't declared in `__init__.py`):
   ```python
   import importlib.util
   import logging
   from pathlib import Path
   from types import ModuleType

   log = logging.getLogger(__name__)

   def _load_module_from_path(path: Path) -> ModuleType:
       spec = importlib.util.spec_from_file_location(path.stem, path)
       module = importlib.util.module_from_spec(spec)
       spec.loader.exec_module(module)
       return module

   def load_scheduled_jobs(jobs_dir: Path) -> list[ModuleType]:
       return _load_jobs(jobs_dir, required_attrs=("TRIGGER", "run"))

   def load_webhook_jobs(jobs_dir: Path) -> list[ModuleType]:
       return _load_jobs(jobs_dir, required_attrs=("EVENTS", "run"))

   def _load_jobs(jobs_dir: Path, required_attrs: tuple[str, ...]) -> list[ModuleType]:
       modules = []
       if not jobs_dir.exists():
           return modules
       for path in sorted(jobs_dir.glob("*.py")):
           if path.name == "__init__.py":
               continue
           try:
               module = _load_module_from_path(path)
               for attr in required_attrs:
                   if not hasattr(module, attr):
                       raise AttributeError(f"missing required attribute '{attr}'")
               modules.append(module)
           except Exception as exc:
               log.error("Failed to load job module %s: %s", path, exc)
       return modules
   ```
2. Catch the broad `Exception` (not just `ImportError`/`AttributeError`) per Requirements section — any error during `exec_module` (syntax error, runtime error at import time) must be caught, logged, and skipped without crashing the loader.

**Testing:**

- Covered by Subtask 15 (`tests/test_job_loader.py`).

