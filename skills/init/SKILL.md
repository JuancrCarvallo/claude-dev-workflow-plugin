---
name: init
description: Configure dev-workflow for this project. Run once per project to set the stack so all other skills adapt automatically.
disable-model-invocation: true
---

# dev-workflow setup

Guide the user through project configuration and write `.claude/dev-workflow.json`.

## Steps

1. Check if `.claude/dev-workflow.json` already exists. If it does, show the current config and ask if they want to reconfigure.

2. Ask the following questions one group at a time — do not dump all questions at once:

**Group 1 — Project type**
- What type of project is this?
  - `backend` — API, server, services
  - `frontend` — UI only
  - `fullstack` — both

**Group 2 — Stack**
- What is the primary language/stack?
  - `node` (JavaScript/TypeScript)
  - `python`
  - `dotnet` (C#)
  - `go`
  - `java`
  - `ruby`
  - `other` (ask them to specify)

**Group 3 — Stack details** (adapt based on Group 2 answer)

For `node`:
- Package manager: `npm` | `yarn` | `pnpm`
- TypeScript: yes | no
- Test framework: `jest` | `vitest` | `mocha` | `other`

For `python`:
- Test framework: `pytest` | `unittest` | `other`
- Package manager: `pip` | `poetry` | `uv`

For `dotnet`:
- Test framework: `xunit` | `nunit` | `mstest`
- Solution file: ask for the .sln filename (e.g. `MyApp.sln`)

For `go`:
- Test framework: `go test` (default, no choice needed)

For `java`:
- Build tool: `maven` | `gradle`
- Test framework: `junit`

For `ruby`:
- Test framework: `rspec` | `minitest`

**Group 4 — Database**
- Does this project use a database? yes | no
- If yes:
  - Database engine: `postgres` | `mysql` | `sqlite` | `sqlserver` | `mongodb` | `other`
  - ORM / query tool: (suggest based on stack — e.g. prisma/typeorm for node, sqlalchemy for python, efcore for dotnet, gorm for go, hibernate for java, activerecord for ruby)

**Group 5 — Task tracker**
- Which task tracker does this project use?
  - `clickup` | `jira` | `github` | `linear` | `none`

**Group 6 — Branch conventions**
- What is the base branch PRs target? (default: `dev`, or `main` if no dev branch)
- Branch naming prefix? (default: task ID — e.g. `CU-abc123`, `PROJ-42`, `#123`)

3. Write the collected answers to `.claude/dev-workflow.json`:

```json
{
  "type": "<frontend|backend|fullstack>",
  "stack": "<node|python|dotnet|go|java|ruby|other>",
  "stack_detail": "<typescript|javascript if node, or stack variant>",
  "package_manager": "<npm|yarn|pnpm|pip|poetry|uv|dotnet|go|maven|gradle|gem>",
  "test_framework": "<jest|vitest|pytest|xunit|go test|junit|rspec|etc>",
  "solution_file": "<MyApp.sln or null>",
  "database": true,
  "db_engine": "<postgres|mysql|sqlite|sqlserver|mongodb|other|null>",
  "orm": "<prisma|typeorm|sequelize|sqlalchemy|efcore|gorm|hibernate|activerecord|null>",
  "task_tracker": "<clickup|jira|github|linear|none>",
  "base_branch": "<dev|main>",
  "branch_prefix": "<CU|PROJ|or empty>"
}
```

**Group 7 — Post-edit hook (optional)**
- Would you like to enable the post-edit build check hook?
  - This runs a lightweight build/syntax check after every file write/edit
  - It adapts to the detected stack (e.g. `tsc --noEmit` for TypeScript, `dotnet build` for .NET, `ruff check` for Python)
  - Answer: yes | no (default: no)

4. If the user chose yes for the hook, append a `PostToolUse` entry to `.claude/settings.json`:

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

If `.claude/settings.json` already has a `hooks` key, merge the new entry into the existing array — do not overwrite.

5. Confirm the written config to the user and tell them:
- All skills (run-terminal, sql-awareness, etc.) will now adapt to this stack automatically
- Re-run `/dev-workflow:init` at any time to reconfigure
- The file should be committed so the whole team shares the same stack config
- If hooks were enabled, the post-edit check runs silently on success and prints errors on failure
