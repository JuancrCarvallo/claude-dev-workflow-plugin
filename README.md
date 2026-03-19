# claude-dev-workflow-plugin

A Claude Code plugin that provides a tech-agnostic development workflow. It orchestrates specialized agents through a structured pipeline (architect → QA → implementation → security review → PR) and adapts all conventions to the detected project stack automatically.

Supports: Node.js (JS/TS), Python, .NET (C#), Go, Java, Ruby.

---

## What it does

- Routes work through a fixed agent pipeline based on intent (feature, bug, question)
- Enforces TDD: tests are written before implementation
- Runs a security and quality review before every PR
- Adapts terminal commands, file conventions, DB/ORM rules, and frontend contract rules to the current stack
- Optionally runs a post-edit build/lint check after every file write

---

## Installation

### 1. Clone into your project's `.claude` directory

```bash
cd your-project
git clone <repo-url> .claude/dev-workflow
```

Or add it as a submodule:

```bash
git submodule add <repo-url> .claude/dev-workflow
```

### 2. Register the hooks

Add the following to your project's `.claude/settings.json`. If the file does not exist, create it.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/dev-workflow/scripts/post-edit.sh \"$CLAUDE_TOOL_INPUT_FILE_PATH\""
          }
        ]
      }
    ]
  }
}
```

Skip this step if you do not want the post-edit build check. You can enable it later via `/dev-workflow:init`.

### 3. Register the agents and skills

Add the plugin paths to `.claude/settings.json` so Claude Code picks up the agents and skills:

```json
{
  "agents": ".claude/dev-workflow/agents",
  "skills": ".claude/dev-workflow/skills"
}
```

If your settings file already has `agents` or `skills` keys, merge the paths rather than replacing them.

### 4. Run the init skill

In a Claude Code session, run:

```
/dev-workflow:init
```

This walks you through a short configuration wizard and writes `.claude/dev-workflow.json` with your stack settings. Commit this file so the whole team shares the same config.

---

## Configuration file

The init skill writes `.claude/dev-workflow.json` at the project root. You can also create or edit it manually:

```json
{
  "type": "backend",
  "stack": "node",
  "stack_detail": "typescript",
  "package_manager": "pnpm",
  "test_framework": "jest",
  "solution_file": null,
  "database": true,
  "db_engine": "postgres",
  "orm": "prisma",
  "task_tracker": "clickup",
  "base_branch": "dev",
  "branch_prefix": "CU"
}
```

| Field | Values |
|-------|--------|
| `type` | `backend` \| `frontend` \| `fullstack` |
| `stack` | `node` \| `python` \| `dotnet` \| `go` \| `java` \| `ruby` \| `other` |
| `stack_detail` | `typescript` \| `javascript` (node only) |
| `package_manager` | `npm` \| `yarn` \| `pnpm` \| `pip` \| `poetry` \| `uv` \| `dotnet` \| `go` \| `maven` \| `gradle` \| `gem` |
| `test_framework` | `jest` \| `vitest` \| `pytest` \| `xunit` \| `go test` \| `junit` \| `rspec` |
| `database` | `true` \| `false` |
| `db_engine` | `postgres` \| `mysql` \| `sqlite` \| `sqlserver` \| `mongodb` \| `other` |
| `orm` | `prisma` \| `typeorm` \| `sequelize` \| `sqlalchemy` \| `efcore` \| `gorm` \| `hibernate` \| `activerecord` |
| `task_tracker` | `clickup` \| `jira` \| `github` \| `linear` \| `none` |
| `base_branch` | `dev` \| `main` (branch PRs target) |
| `branch_prefix` | e.g. `CU`, `PROJ`, `#`, or empty |

If `.claude/dev-workflow.json` is absent, `detect-stack.sh` falls back to auto-detection from project files (`package.json`, `go.mod`, `*.sln`, etc.).

---

## Agent pipeline

### Feature workflow

```
Orchestrator
  └── architect        reads codebase, designs solution, creates subtasks
  └── qa               writes failing tests (TDD red phase)
  └── implementation   makes tests pass (TDD green phase)
  └── review-security  security + quality gate
  └── Orchestrator     creates PR
```

### Bug workflow

```
Orchestrator
  └── bugfix           reproduces, isolates, patches, verifies
  └── review-security  security + quality gate
  └── Orchestrator     creates PR
```

### Question

Answered directly by the orchestrator using the `read-codebase` skill. No agents invoked.

---

## Skills reference

Skills are loaded by agents as needed. They are not user-invocable (except `init`).

| Skill | Loaded by | Purpose |
|-------|-----------|---------|
| `init` | User (`/dev-workflow:init`) | Project configuration wizard |
| `read-codebase` | All agents | Stack-aware codebase navigation conventions |
| `write-edit-files` | qa, implementation, bugfix, review-security | Stack-aware file writing conventions |
| `run-terminal` | qa, implementation, bugfix, review-security | Stack-aware build/test/install commands |
| `sql-awareness` | implementation, bugfix, review-security | ORM-specific query safety rules |
| `frontend-awareness` | architect, review-security | API contract rules (inward for frontend, outward for backend) |

---

## Post-edit hook

When enabled, `post-edit.sh` runs a lightweight check after every file write or edit. It is silent on success and prints errors on failure.

| Stack | Check |
|-------|-------|
| Node + TypeScript | `tsc --noEmit` |
| Node + JS | ESLint (if configured) |
| .NET | `dotnet build --no-restore` |
| Python | `ruff check` → `flake8` → `py_compile` |
| Go | `go build ./...` |
| Java (Maven) | `mvn compile -q` |
| Java (Gradle) | `./gradlew compileJava -q` |
| Ruby | `ruby -c <file>` |

---

## Project structure

```
.claude/dev-workflow/
  agents/
    orchestrator.md          # Central hub — routes all work
    architect-agent.md       # Designs solution, creates subtasks
    qa-agent.md              # Writes failing tests (TDD red)
    implementation-agent.md  # Implements code (TDD green)
    review-security-agent.md # Security and quality gate
    bugfix-agent.md          # Reproduces and patches bugs
  skills/
    init/SKILL.md            # Configuration wizard
    read-codebase/SKILL.md   # Codebase navigation conventions
    write-edit-files/SKILL.md# File writing conventions
    run-terminal/SKILL.md    # Terminal command conventions
    sql-awareness/SKILL.md   # DB/ORM safety rules
    frontend-awareness/SKILL.md # API contract awareness
  scripts/
    detect-stack.sh          # Stack detection and config loading
    codebase-conventions.sh  # Generates read-codebase skill content
    write-conventions.sh     # Generates write-edit-files skill content
    terminal-conventions.sh  # Generates run-terminal skill content
    sql-conventions.sh       # Generates sql-awareness skill content
    frontend-awareness.sh    # Generates frontend-awareness skill content
    post-edit.sh             # Post-edit build/lint hook
  hooks/
    hooks.json               # Hook definitions
  .claude-plugin/
    plugin.json              # Plugin manifest
```

---

## Adding a new stack

1. Add detection logic to `scripts/detect-stack.sh` (new `elif` branch in the auto-detect section).
2. Add a `case` branch to each of the five convention scripts (`terminal-conventions.sh`, `codebase-conventions.sh`, `write-conventions.sh`, `sql-conventions.sh`, and optionally `frontend-awareness.sh`).
3. Add the new stack option to `skills/init/SKILL.md` so the wizard presents it.

---

## Adding a new agent

1. Create `agents/<name>-agent.md` following the same frontmatter format:

```markdown
---
name: <name>
description: <one-line description>
skills:
  - read-codebase
  - write-edit-files
---
```

2. Define Role, Activation, Workflow, Constraints, and Return Payload sections.
3. Add the agent to the orchestrator routing table in `agents/orchestrator.md`.

---

## Adding a new skill

1. Create `skills/<name>/SKILL.md`.
2. If the skill needs stack-aware content, create `scripts/<name>.sh` and reference it in the skill with `!`command`` injection:

```markdown
!`${CLAUDE_SKILL_DIR}/../../scripts/<name>.sh`
```

3. Reference the skill by name in any agent's `skills:` frontmatter list.

---

## Security notes

- The post-edit hook runs shell commands automatically. Review `post-edit.sh` before enabling it.
- `detect-stack.sh` reads local project files only — it makes no network calls.
- DB migrations are never applied automatically. The implementation agent generates migration files only; a human must apply them.
- The review-security agent blocks PR creation on any CRITICAL finding (SQL injection, hardcoded secrets, missing auth, IDOR, mass assignment).
