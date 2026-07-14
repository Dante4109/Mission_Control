The custom agent isn't wired into the session's agent registry yet (that's a Claude Code restart/reload thing). I'll apply the `github-issue-creator` instructions directly — same output, same BDD format.

---

## MC-0002 Set Up Claude-Based Agentic Issue Pipeline Workflow

**Story Title:** Claude-Based GH Issue Pipeline with Orchestrator and Subagents

**As a** developer working on a GitHub issue  
**I want** a Claude Code orchestrator that runs a sequential pipeline of specialized subagents  
**So that** each issue is consistently analyzed, planned, implemented, and reviewed through a structured, automated workflow

---

### Acceptance Criteria

**Given** a GitHub issue exists in the repository  
**When** the GH Issue Pipeline Agent (Orchestrator) is invoked with the issue reference  
**Then** it runs each subagent in sequence — User Story → Start → Analyze → Plan → Implementation → Code Review — waiting for each to complete before advancing

---

**Given** the Orchestrator has received an issue  
**When** the Github Issue User Story Agent runs  
**Then** it produces or refines a BDD-formatted user story (As a / I want / So that + Given/When/Then acceptance criteria) and outputs it for the next stage

---

**Given** the user story is confirmed  
**When** the Issue Start Agent runs  
**Then** it creates the working branch, loads relevant codebase context, and confirms the environment is ready for development

---

**Given** the branch and context are initialized  
**When** the Issue Analyze Agent runs  
**Then** it produces a structured analysis of the requirements against the existing codebase, identifying affected files, dependencies, and constraints

---

**Given** the analysis is complete  
**When** the Issue Plan Agent runs  
**Then** it outputs a step-by-step implementation plan with file targets, approach rationale, and a verification strategy

---

**Given** the plan is approved  
**When** the Implementation Agent runs  
**Then** it executes the planned changes, commits them to the branch, and confirms all changes match the plan

---

**Given** the implementation is committed  
**When** the Code Review Agent runs  
**Then** it reviews the diff for correctness, security, and quality, and either approves or returns specific actionable findings

---

**Given** the Code Review Agent approves  
**When** the Orchestrator receives the final result  
**Then** it posts a summary of the pipeline run (each stage result) and marks the issue ready for PR

---

### Edge Cases & Error Handling

- If any subagent fails or returns unresolved findings, the Orchestrator halts the pipeline and reports which stage failed and why — it does not advance to the next stage
- If the Issue Plan Agent produces a plan the user rejects, the Orchestrator loops back to the Analyze stage rather than proceeding
- If the Code Review Agent returns findings, the Implementation Agent re-runs with the findings as additional context before review repeats
- If the Issue Start Agent cannot create the branch (e.g., branch already exists, conflict), it surfaces the conflict before any further stages run
- The Orchestrator must be idempotent — re-running from a partially completed pipeline resumes at the last incomplete stage rather than starting over
