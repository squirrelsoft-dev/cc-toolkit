# CC Toolkit — Lightweight Claude Code Project Kit

A minimal, composable toolkit for scaffolding and optimizing Claude Code projects. Unlike monolithic plugin suites with 50+ agents, this kit gives you a small set of high-value primitives that you customize per project.

## Philosophy

1. **Start lean, add on demand** — No bloated global config. Each project gets exactly what it needs.
2. **Hooks > Agents for common tasks** — Most quality gates don't need a full agent. A 5-line hook does the job.
3. **Commands are reusable prompts** — Package your best prompts as slash commands, iterate on them over time.
4. **Rules are scoped context** — Path-specific rules load only when relevant, keeping context tight.
5. **Shell aliases are muscle memory** — 2-3 characters to launch Claude with the right context every time.

## Quick Start

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/squirrelsoft-dev/cc-toolkit/install.sh | bash
```

Or clone manually:

```bash
git clone https://github.com/squirrelsoft-dev/claude-code-flow.git
ln -s $(pwd)/claude-code-flow/cc-toolkit ~/cc-toolkit
echo 'source ~/cc-toolkit/shell-aliases.sh' >> ~/.zshrc
```

Then scaffold any project:

```bash
cd your-project
ccinit
```

## What's Included

```
cc-toolkit/
├── README.md
├── install.sh                   # curl-installable setup script
├── init.sh                      # Project scaffolder — run once per project
├── shell-aliases.sh             # Source in ~/.zshrc or ~/.bashrc
└── templates/
    ├── CLAUDE.md.tmpl
    ├── settings.json.tmpl
    ├── settings.local.json.tmpl
    ├── rules/
    │   ├── general.md
    │   ├── api.md
    │   ├── frontend.md
    │   ├── testing.md
    │   └── security.md
    ├── hooks/
    │   ├── stop-typecheck.ts
    │   ├── stop-quality-gate.sh
    │   ├── guard.sh
    │   ├── task-summary.sh
    │   └── save-context.sh
    ├── commands/
    │   ├── plan.md
    │   ├── scaffold.md
    │   ├── commit.md
    │   ├── pr.md
    │   ├── fix-issue.md
    │   ├── review.md
    │   └── security-scan.md
    └── agents/
        ├── architect.md
        └── implementer.md
```

## Customization

The `init.sh` scaffolder asks a few questions (stack, test runner, formatter) and generates a tailored `.claude/` setup. After scaffolding:

- Edit `CLAUDE.md` — add project-specific commands and gotchas as you discover them
- Edit `.claude/rules/` — add/remove rule files for your stack
- Edit `.claude/settings.json` — tune hooks for your build tools
- Add commands to `.claude/commands/` — package your best prompts

The entire `.claude/` directory is committed to git so your team shares the same setup.

## Security & Analysis Tools

The installer optionally sets up free, open-source tools that integrate with the hooks:

| Tool | What it catches | Hook |
|------|----------------|------|
| **Gitleaks** | Hardcoded secrets, API keys, tokens | Stop gate |
| **Semgrep** | SAST — injection, XSS, OWASP Top 10 | Stop gate |
| **Trivy** | Dependency vulns, license issues, IaC misconfig | `/security-scan` |
| **Oxlint** | Fast linting (100x faster than ESLint) | PostToolUse |
| **eslint-plugin-security** | JS/TS security antipatterns | PostToolUse |
| **Knip** | Dead code, unused exports/deps | `/security-scan` |
| **Madge** | Circular dependencies | `/security-scan` |

All hooks gracefully skip tools that aren't installed — nothing breaks if you don't have them.
