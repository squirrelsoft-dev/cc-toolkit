---
description: "Break a high-level task into subtasks with dependency tracking"
---

# Task Breakdown

Use the Task tool to spawn a Plan agent in plan mode to break down the following task: `$ARGUMENTS`

**Important** - This agent does not produce code or create any output other than generating the complete tasks file.

The agent should:

1. **Understand** — Restate the task. Ask clarifying questions if the scope is ambiguous.
2. **Research** — Read relevant files to understand the codebase, architecture, and existing patterns.
3. **Decompose** — Break the task into the smallest meaningful units of work.
4. **Identify dependencies** — For each task, determine if it is:
   - **Non-blocking** — independent, can be done anytime
   - **Blocked by** — cannot start until specific other tasks complete (list them)
   - **Blocking** — other tasks cannot start until this one completes (list them)
5. **Group for parallelism** — Organize tasks into groups that can be worked on simultaneously. Tasks in the same group have no dependencies on each other. Later groups depend on earlier groups.
6. **Save** — Create the `.claude/tasks/` directory if needed, then write the breakdown to `.claude/tasks/$ARGUMENTS.md` (kebab-case the filename).

## Output Format

```markdown
# Task Breakdown: <feature name>

> <one-sentence summary>

## Group 1 — <label>
_Tasks in this group can be done in parallel._

- [ ] **Task title** `[S/M/L]`
  <what to do and why>
  Files: `path/to/file`
  Blocking: <task titles this enables, or "None">

- [ ] **Task title** `[S/M/L]`
  <what to do and why>
  Files: `path/to/file`
  Non-blocking

## Group 2 — <label>
_Depends on: Group 1_

- [ ] **Task title** `[S/M/L]`
  <what to do and why>
  Files: `path/to/file`
  Blocked by: <task titles from earlier groups>
  Blocking: <task titles in later groups, or "None">

## Group N — <label>
_Depends on: Group N-1_

- [ ] **Task title** `[S/M/L]`
  <what to do and why>
  Files: `path/to/file`
  Blocked by: <task titles from earlier groups>
```

## Rules

- Complexity: `S` (< 30 min), `M` (30 min–2 hrs), `L` (2+ hrs)
- Do NOT implement anything — only produce the task file
- After saving, print the full task list for the user to review
