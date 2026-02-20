---
description: 'Generate conventional commit message from staged changes'
---

# Commit Message Generator

Analyze the staged changes (`git diff --cached`) and generate a conventional commit message.

## Format

```
<type>(<scope>): <short description>

<body — what changed and why>

<footer — closes/fixes issues if applicable>
```

## Types

feat, fix, docs, style, refactor, test, chore, perf, ci, build

## Rules

- Scope is the primary module/feature affected
- Description is imperative, lowercase, no period
- Body explains what and why, not how
- Reference issue numbers if identifiable from branch name or diff context

## Workflow

1. Run `git status` to see all changes (staged, unstaged, and untracked)
2. Run `git diff` and `git diff --cached` to review changes
3. If there are no staged changes, stage the appropriate files using `git add <file>...` (prefer specific files over `git add -A`)
4. Generate the commit message based on all staged changes
5. Run `git commit` with the generated message
