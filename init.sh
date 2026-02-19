#!/usr/bin/env bash
set -euo pipefail

# CC Toolkit — Project Scaffolder
# Run this once per project to generate a .claude/ setup tailored to your stack.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-.}"

echo "🔧 CC Toolkit — Project Scaffolder"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detect or ask for stack
detect_stack() {
  if [[ -f "$PROJECT_DIR/package.json" ]]; then
    PKG_MANAGER="npm"
    [[ -f "$PROJECT_DIR/bun.lockb" ]] && PKG_MANAGER="bun"
    [[ -f "$PROJECT_DIR/pnpm-lock.yaml" ]] && PKG_MANAGER="pnpm"
    [[ -f "$PROJECT_DIR/yarn.lock" ]] && PKG_MANAGER="yarn"

    if grep -q '"next"' "$PROJECT_DIR/package.json" 2>/dev/null; then
      FRAMEWORK="nextjs"
    elif grep -q '"react"' "$PROJECT_DIR/package.json" 2>/dev/null; then
      FRAMEWORK="react"
    elif grep -q '"express"' "$PROJECT_DIR/package.json" 2>/dev/null; then
      FRAMEWORK="express"
    else
      FRAMEWORK="node"
    fi

    LANG="typescript"
    [[ ! -f "$PROJECT_DIR/tsconfig.json" ]] && LANG="javascript"

    # Detect test runner
    TEST_CMD="$PKG_MANAGER test"
    grep -q '"vitest"' "$PROJECT_DIR/package.json" 2>/dev/null && TEST_CMD="$PKG_MANAGER run test"
    grep -q '"jest"' "$PROJECT_DIR/package.json" 2>/dev/null && TEST_CMD="$PKG_MANAGER test"

    # Detect formatter
    FORMATTER="prettier"
    grep -q '"biome"' "$PROJECT_DIR/package.json" 2>/dev/null && FORMATTER="biome"

    # Detect typecheck
    TYPECHECK_CMD=""
    if [[ "$LANG" == "typescript" ]]; then
      TYPECHECK_CMD="$PKG_MANAGER run typecheck 2>/dev/null || npx tsc --noEmit"
    fi

    echo "  Detected: $FRAMEWORK ($LANG) with $PKG_MANAGER"
    echo "  Test: $TEST_CMD"
    echo "  Format: $FORMATTER"
    [[ -n "$TYPECHECK_CMD" ]] && echo "  Typecheck: $TYPECHECK_CMD"

  elif [[ -f "$PROJECT_DIR/requirements.txt" ]] || [[ -f "$PROJECT_DIR/pyproject.toml" ]]; then
    LANG="python"
    FRAMEWORK="python"
    PKG_MANAGER="pip"
    TEST_CMD="pytest"
    FORMATTER="ruff"
    TYPECHECK_CMD="mypy ."
    echo "  Detected: Python project"

  elif [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
    LANG="rust"
    FRAMEWORK="rust"
    PKG_MANAGER="cargo"
    TEST_CMD="cargo test"
    FORMATTER="rustfmt"
    TYPECHECK_CMD="cargo check"
    echo "  Detected: Rust project"

  elif [[ -f "$PROJECT_DIR/go.mod" ]]; then
    LANG="go"
    FRAMEWORK="go"
    PKG_MANAGER="go"
    TEST_CMD="go test ./..."
    FORMATTER="gofmt"
    TYPECHECK_CMD="go vet ./..."
    echo "  Detected: Go project"

  else
    LANG="typescript"
    FRAMEWORK="node"
    PKG_MANAGER="npm"
    TEST_CMD="npm test"
    FORMATTER="prettier"
    TYPECHECK_CMD="npx tsc --noEmit"
    echo "  No project detected — defaulting to Node/TypeScript"
  fi
}

detect_stack
echo ""

# Create directory structure
echo "📁 Creating .claude/ structure..."
mkdir -p "$PROJECT_DIR/.claude/commands"
mkdir -p "$PROJECT_DIR/.claude/hooks"
mkdir -p "$PROJECT_DIR/.claude/rules"

# --- CLAUDE.md ---
echo "📝 Generating CLAUDE.md..."

INSTALL_CMD="$PKG_MANAGER install"
[[ "$PKG_MANAGER" == "go" ]] && INSTALL_CMD="go mod download"
[[ "$PKG_MANAGER" == "cargo" ]] && INSTALL_CMD="cargo build"
[[ "$PKG_MANAGER" == "pip" ]] && INSTALL_CMD="pip install -r requirements.txt"

BUILD_CMD="$PKG_MANAGER run build"
[[ "$PKG_MANAGER" == "cargo" ]] && BUILD_CMD="cargo build --release"
[[ "$PKG_MANAGER" == "go" ]] && BUILD_CMD="go build ./..."
[[ "$PKG_MANAGER" == "pip" ]] && BUILD_CMD="# no build step"

LINT_CMD="$PKG_MANAGER run lint"
[[ "$LANG" == "python" ]] && LINT_CMD="ruff check ."
[[ "$LANG" == "rust" ]] && LINT_CMD="cargo clippy"
[[ "$LANG" == "go" ]] && LINT_CMD="golangci-lint run"

cat > "$PROJECT_DIR/CLAUDE.md" << CLAUDEMD
# Project Commands
- Install: \`$INSTALL_CMD\`
- Build: \`$BUILD_CMD\`
- Test: \`$TEST_CMD\`
- Lint: \`$LINT_CMD\`
$([ -n "$TYPECHECK_CMD" ] && echo "- Typecheck: \`$TYPECHECK_CMD\`")

# Non-Negotiables
- Do not add new dependencies without a strong reason
- Always include verification steps after code changes
- Run tests before marking any task complete

# Common Mistakes
- (add rules here as you discover repeated issues)

# Learnings
- (add patterns from PR reviews here)
CLAUDEMD

# --- settings.json (team hooks) ---
echo "⚙️  Generating .claude/settings.json..."

# Build format command based on detected formatter
if [[ "$FORMATTER" == "prettier" ]]; then
  FORMAT_CMD='npx prettier --write \"$CLAUDE_TOOL_INPUT_FILE_PATH\" 2>/dev/null || true'
elif [[ "$FORMATTER" == "biome" ]]; then
  FORMAT_CMD='npx biome format --write \"$CLAUDE_TOOL_INPUT_FILE_PATH\" 2>/dev/null || true'
elif [[ "$FORMATTER" == "ruff" ]]; then
  FORMAT_CMD='ruff format \"$CLAUDE_TOOL_INPUT_FILE_PATH\" 2>/dev/null || true'
elif [[ "$FORMATTER" == "rustfmt" ]]; then
  FORMAT_CMD='rustfmt \"$CLAUDE_TOOL_INPUT_FILE_PATH\" 2>/dev/null || true'
elif [[ "$FORMATTER" == "gofmt" ]]; then
  FORMAT_CMD='gofmt -w \"$CLAUDE_TOOL_INPUT_FILE_PATH\" 2>/dev/null || true'
fi

# Build stop hook test command
STOP_TEST_CMD="$TEST_CMD --passWithNoTests 2>&1 | tail -20"
[[ "$LANG" == "python" ]] && STOP_TEST_CMD="pytest --tb=short -q 2>&1 | tail -20"
[[ "$LANG" == "rust" ]] && STOP_TEST_CMD="cargo test 2>&1 | tail -20"
[[ "$LANG" == "go" ]] && STOP_TEST_CMD="go test ./... 2>&1 | tail -20"

cat > "$PROJECT_DIR/.claude/settings.json" << SETTINGS
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$FORMAT_CMD"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$STOP_TEST_CMD"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo '## Git State' && git status --short && echo '' && echo '## Recent Commits' && git log --oneline -5"
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [
      "$TEST_CMD",
      "$LINT_CMD",
      "$BUILD_CMD",
      "git commit*",
      "git push*",
      "git checkout*",
      "git branch*"
    ]
  }
}
SETTINGS

# --- settings.local.json (personal hooks) ---
echo "🔒 Generating .claude/settings.local.json..."

cat > "$PROJECT_DIR/.claude/settings.local.json" << LOCALSET
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo ''"
          }
        ]
      }
    ]
  }
}
LOCALSET

# --- Rules ---
echo "📏 Generating rules..."

cat > "$PROJECT_DIR/.claude/rules/general.md" << 'RULES'
# General Rules

- Diagnose before fixing: explain possible causes before changing code
- Functions should be no more than 50 lines; break larger ones into helpers
- Single responsibility per function/module
- Descriptive names: `calculateInvoiceTotal` not `doCalc`
- Remove commented-out code and debug statements before completing
- Never swallow exceptions silently
RULES

if [[ "$LANG" == "typescript" ]] || [[ "$LANG" == "javascript" ]]; then
cat > "$PROJECT_DIR/.claude/rules/api.md" << 'RULES'
---
paths:
  - "src/api/**/*.{ts,tsx,js,jsx}"
  - "src/routes/**/*.{ts,tsx,js,jsx}"
  - "src/server/**/*.{ts,tsx,js,jsx}"
  - "app/api/**/*.{ts,tsx,js,jsx}"
---

# API Rules

- All endpoints must include input validation
- Use typed request/response schemas
- Return consistent error formats with appropriate HTTP status codes
- Include rate limiting on public endpoints
- Use parameterized queries or ORM — never raw string interpolation for SQL
RULES

cat > "$PROJECT_DIR/.claude/rules/frontend.md" << 'RULES'
---
paths:
  - "src/components/**/*.{tsx,jsx}"
  - "src/app/**/*.{tsx,jsx}"
  - "app/**/*.{tsx,jsx}"
---

# Frontend Rules

- Components should be focused and composable
- Include error boundaries and loading states
- Use semantic HTML and ARIA attributes for accessibility
- Keep component files under 200 lines; extract subcomponents
- Co-locate styles, types, and tests with components
RULES
fi

cat > "$PROJECT_DIR/.claude/rules/testing.md" << 'RULES'
---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/__tests__/**"
  - "tests/**"
---

# Testing Rules

- Test behavior, not implementation details
- Include edge cases: empty inputs, null values, boundary conditions
- Use descriptive test names that explain what is being verified
- One assertion per test when possible
- Mock external services, never hit real APIs in tests
RULES

# --- Hooks (file-based) ---
echo "🪝 Generating hooks..."

if [[ "$LANG" == "typescript" ]]; then
cat > "$PROJECT_DIR/.claude/hooks/stop-typecheck.ts" << 'HOOK'
import type { StopHookInput, HookJSONOutput } from "@anthropic-ai/claude-agent-sdk";

const input: StopHookInput = await Bun.stdin.json();

const gitStatus = await Bun.$`git status --porcelain`.quiet().text();

if (gitStatus.trim().length === 0) {
  const output: HookJSONOutput = { decision: "approve" };
  console.log(JSON.stringify(output));
  process.exit(0);
}

const typecheckErrors = await Bun.$`bun typecheck 2>&1 || npx tsc --noEmit 2>&1`.throws(false).quiet().text();

if (typecheckErrors.trim().length > 0 && typecheckErrors.includes("error TS")) {
  const output: HookJSONOutput = {
    decision: "block",
    reason: `Type errors detected. Fix these before stopping.\n\n${typecheckErrors}`,
  };
  console.log(JSON.stringify(output));
  process.exit(0);
}

const output: HookJSONOutput = { decision: "approve" };
console.log(JSON.stringify(output));
HOOK
fi

# --- Commands ---
echo "📋 Generating commands..."

cat > "$PROJECT_DIR/.claude/commands/plan.md" << 'CMD'
---
description: "Structured planning before implementation"
---

# Planning Workflow

You are entering **Plan Mode**. Do NOT write any code yet.

## Steps

1. **Understand** — Restate the request in your own words. Ask clarifying questions if anything is ambiguous.
2. **Research** — Read relevant files to understand the current architecture and patterns.
3. **Decompose** — Break the work into discrete tasks (max 5). For each task:
   - What files will be created or modified
   - What the change does
   - Dependencies on other tasks
   - Estimated complexity (S/M/L)
4. **Risks** — Identify edge cases, breaking changes, or areas of uncertainty.
5. **Present** — Show the plan and wait for approval before proceeding.

Do NOT implement anything until the user approves the plan.
CMD

cat > "$PROJECT_DIR/.claude/commands/scaffold.md" << 'CMD'
---
description: "Generate feature directory structure with boilerplate"
---

# Feature Scaffold

Create a complete feature directory for `$ARGUMENTS` following project conventions.

## Steps

1. **Analyze** existing features in the codebase for patterns (directory structure, naming, exports).
2. **Generate** the feature directory with:
   - Main component/module file
   - Type definitions
   - Unit test file with at least 3 test cases (render, interaction, error state)
   - Index/barrel export
   - README with usage examples
3. **Create a feature branch**: `feature/$ARGUMENTS`
4. **Verify** the generated files pass linting and type checks.
5. **Stage** the generated files.

Follow existing patterns exactly. Do not invent new conventions.
CMD

cat > "$PROJECT_DIR/.claude/commands/commit.md" << 'CMD'
---
description: "Generate conventional commit message from staged changes"
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

Output ONLY the commit message, nothing else. Then run `git commit -m "<message>"`.
CMD

cat > "$PROJECT_DIR/.claude/commands/pr.md" << 'CMD'
---
description: "Create a pull request with full context"
---

# Pull Request Generator

Create a comprehensive PR for the current branch.

## Steps

1. **Diff analysis** — Run `git diff main...HEAD` to understand all changes.
2. **Generate PR body:**
   - **What changed** — bullet points of key changes
   - **Why** — business context and motivation
   - **How to test** — step-by-step verification instructions
   - **Test coverage** — what tests were added/modified
   - **Breaking changes** — if any
3. **Generate title** — conventional format: `type(scope): description`
4. **Create PR** — use `gh pr create --title "..." --body "..."` to open the PR.
5. **Link issues** — scan commits for issue references and include `Closes #N` in the body.
CMD

cat > "$PROJECT_DIR/.claude/commands/fix-issue.md" << 'CMD'
---
description: "Analyze and fix a GitHub issue end-to-end"
---

# Fix GitHub Issue

Resolve issue `$ARGUMENTS` from analysis through PR creation.

## Steps

1. **Fetch** — `gh issue view $ARGUMENTS` to get the full issue context.
2. **Analyze** — Identify affected files, root cause, and reproduction steps.
3. **Branch** — Create `fix/issue-$ARGUMENTS` from latest main.
4. **Implement** — Make the minimal fix following existing code patterns.
5. **Test** — Write a regression test that fails without the fix and passes with it.
6. **Verify** — Run the full test suite. Ensure no regressions.
7. **Commit** — Use conventional commit format referencing the issue.
8. **PR** — Create a PR that auto-closes the issue with full context.

Keep the change minimal. Fix the bug, add the test, nothing else.
CMD

cat > "$PROJECT_DIR/.claude/commands/review.md" << 'CMD'
---
description: "Review staged or uncommitted changes"
---

# Code Review

Review the current changes for quality, bugs, and security issues.

## Steps

1. **Gather** — Run `git diff` (or `git diff --cached` if changes are staged).
2. **Analyze** each changed file for:
   - **Bugs** — logic errors, off-by-one, null handling, race conditions
   - **Security** — injection, auth bypasses, hardcoded secrets, XSS
   - **Performance** — N+1 queries, unnecessary re-renders, missing indexes
   - **Style** — naming, complexity, DRY violations
3. **Summarize** findings as:
   - 🔴 **Critical** — must fix before merge
   - 🟡 **Warning** — should fix, not a blocker
   - 🟢 **Suggestion** — nice to have
4. **Suggest** specific fixes for each critical and warning item.
CMD

# --- Agents ---
echo "🤖 Generating agents..."
mkdir -p "$PROJECT_DIR/.claude/agents"

cat > "$PROJECT_DIR/.claude/agents/architect.md" << 'AGENT'
---
name: architect
description: "Plans features and makes architecture decisions"
tools: Read, Grep, Glob, WebFetch
permissionMode: manual
---

# Architect Agent

You are a senior architect. Your job is to plan, not implement.

## Responsibilities
- Analyze requirements and decompose into tasks
- Make technology and pattern decisions with rationale
- Identify risks, edge cases, and dependencies
- Produce implementation specs that another agent can execute

## Output Format
Always produce a structured plan with:
1. Overview (what and why)
2. Task breakdown (what, where, dependencies, complexity)
3. Technical decisions (with alternatives considered)
4. Risks and mitigations
5. Acceptance criteria

Never write implementation code. Your output is the plan.
AGENT

cat > "$PROJECT_DIR/.claude/agents/implementer.md" << 'AGENT'
---
name: implementer
description: "Implements code from specs and plans"
tools: Read, Write, Edit, Bash, Grep, Glob
permissionMode: acceptEdits
---

# Implementer Agent

You implement code based on plans and specifications.

## Responsibilities
- Follow the provided plan exactly
- Write clean, tested, documented code
- Follow existing project patterns (check similar files first)
- Run tests after every significant change
- Report back what was done and any deviations from the plan

## Rules
- Read existing code before writing new code
- Match the style of surrounding code
- Never skip tests
- If the plan is ambiguous, stop and ask — don't guess
AGENT

# --- .gitignore additions ---
echo "📄 Updating .gitignore..."
if [[ -f "$PROJECT_DIR/.gitignore" ]]; then
  if ! grep -q "CLAUDE.local.md" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
    echo "" >> "$PROJECT_DIR/.gitignore"
    echo "# Claude Code personal files" >> "$PROJECT_DIR/.gitignore"
    echo "CLAUDE.local.md" >> "$PROJECT_DIR/.gitignore"
    echo ".claude/settings.local.json" >> "$PROJECT_DIR/.gitignore"
  fi
else
  cat > "$PROJECT_DIR/.gitignore" << 'GITIGNORE'
# Claude Code personal files
CLAUDE.local.md
.claude/settings.local.json
GITIGNORE
fi

echo ""
echo "✅ Done! Generated:"
echo ""
echo "  CLAUDE.md                        — Project context (edit this!)"
echo "  .claude/settings.json            — Team hooks + permissions"
echo "  .claude/settings.local.json      — Personal hooks (gitignored)"
echo "  .claude/rules/                   — Path-scoped rules"
echo "  .claude/hooks/                   — TypeScript/bash hook scripts"
echo "  .claude/commands/                — Slash commands"
echo "  .claude/agents/                  — Subagent definitions"
echo ""
echo "Next steps:"
echo "  1. Review and customize CLAUDE.md for your project"
echo "  2. Remove rules/ files that don't apply to your stack"
echo "  3. Adjust hooks in settings.json for your build tools"
echo "  4. Commit .claude/ to git so your team shares the setup"
echo ""
