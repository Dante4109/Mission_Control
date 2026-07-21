# GitHub Issue #1 — Verbatim Content

**Repository:** Planka (https://github.com/Dante4109/Planka)
**Issue Number:** 1
**Issue URL:** https://github.com/Dante4109/Planka/issues/1

---

## Issue Metadata

| Field | Value |
|-------|-------|
| **Title** | P-0001: Scheduled and Webhook-Driven Job System for Planka Tools |
| **State** | OPEN |
| **Author** | Dante4109 (RJ Zeller) |
| **Assignees** | None |
| **Labels** | None |
| **Milestone** | None |
| **Created** | 2026-07-21T03:18:14Z |
| **Updated** | 2026-07-21T03:18:14Z |
| **Comments** | 0 |

---

## Issue Body

**As a** Planka Tools user
**I want** a scheduled and event-driven job system that can invoke any method in `client.py`
**So that** I can automate recurring board maintenance and card-lifecycle actions without manual intervention

## Summary

Create a job system for Planka Tools that supports two trigger types — time-based schedules (via APScheduler) and webhook-driven events (e.g., card created/moved/updated/deleted). Any method in `C:\projects\AppDev\Planka\src\planka_tools\api\client.py` should be callable from within a job script. Each job should be isolated to its own file, organized into folders by job type (`Scheduled`, `Webhook`), with subfolders as the number of jobs grows.

## Acceptance Criteria

- **Given** a job is defined with an APScheduler-style time trigger (e.g., daily at a specific time, a specific day of week, or every X hours)
  **When** the scheduled time is reached
  **Then** the job's action script executes and calls the appropriate `client.py` method(s)

- **Given** a webhook event occurs for a card (created, moved, updated, or deleted)
  **When** the webhook is received by the existing webhook sidecar
  **Then** the matching webhook job (if any) is triggered and executes its action

- **Given** a new job script is added to the `Scheduled` or `Webhook` folder
  **When** the job system starts or reloads
  **Then** the job is automatically discovered and registered without requiring changes to core job-runner code

- **Given** a job script calls a method from `client.py`
  **When** the method executes successfully
  **Then** the resulting state change (e.g., cards moved/copied) is reflected in Planka

- **Given** the "Move Tomorrow → Today" scheduled job (daily at 8:00 AM)
  **When** the trigger fires
  **Then** all cards in list "Tomorrow" on board "Daily Workflow" (project "Trello Import") are moved to list "Today"

- **Given** the "Move This Month → This Week" scheduled job (1st of month at 4:00 AM)
  **When** the trigger fires
  **Then** all cards in list "This Month" on board "Daily Workflow" (project "Trello Import") are moved to list "This Week"

- **Given** the "Past-Due" scheduled job (daily at 11:59 PM)
  **When** the trigger fires
  **Then** each card with a due date in the past is moved to list "Past-Due" on board "Daily Workflow" (project "Trello Import")

- **Given** the "Copy Daily → Today" scheduled job (daily at 6:00 AM)
  **When** the trigger fires
  **Then** each card in list "Daily" on board "Personal" (project "Trello Import") is copied to list "Today" on board "Daily Workflow" (project "Trello Import")

- **Given** the "Auto-assign on In-Progress" webhook job
  **When** a card is moved to list "In-Progress" on board "Daily Workflow" (project "Trello Import")
  **Then** the configured user is assigned to that card

## Edge Cases & Error Handling

- A scheduled job's target list/board/project does not exist or has been renamed/deleted
- A webhook event references a card, list, or board that no longer exists
- Overlapping/duplicate triggers firing for the same job (e.g., scheduler restart replays a missed run)
- A `client.py` method call fails (network error, API error, auth failure) — job should log and fail gracefully without crashing the runner
- Two jobs act on the same card concurrently (e.g., a scheduled "Past-Due" move and a webhook-triggered move happen at the same time)
- Malformed or missing job definition file in the `Scheduled`/`Webhook` folder

---

**Source:** `notes/automation ideas/To-Do/Planka Job System.md`
