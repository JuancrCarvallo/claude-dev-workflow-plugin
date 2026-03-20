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

**Group 8 — Codebase scan (optional)**
- Would you like to scan the codebase now to give all agents project context?
  - This reads key files and writes `.claude/dev-workflow-context.md`
  - Agents load this automatically — no extra steps needed
  - Answer: yes | no (default: yes)

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

5. If the user chose yes for the codebase scan, perform the scan and write three files into `.claude/dev-workflow-context/`.

Each file is loaded automatically by the matching skill — no manual wiring needed.

---

### Scan procedure

Read only what is needed. Do not load entire directories. Skip a section if it does not apply. Max 10 files read total.

**Step 1 — Identify the entry point and bootstrap**
- Find the main application file (e.g. `src/index.ts`, `main.py`, `Program.cs`, `cmd/main.go`).
- Read the first 60 lines to understand middleware order, DI setup, and route registration.

**Step 2 — Map the layer structure**
- List directories up to depth 2. Exclude: `node_modules`, `.git`, `dist`, `build`, `bin`, `obj`, `.next`, `__pycache__`.
- Map each directory to its layer role: presentation / application / domain / infrastructure / test.

**Step 3 — Routing and response conventions**
- Find where routes or controllers are defined. Read one representative file (controller or router).
- Extract: response shape for success and error, HTTP status code patterns, pagination shape if any.

**Step 4 — Auth mechanism**
- Grep for auth middleware, guards, JWT, or session usage.
- Note: file path, mechanism (JWT/session/API key), opt-in or opt-out per route.

**Step 5 — Test layout**
- Find test directories. Read one test file.
- Extract: file naming pattern, base class or fixture used, whether tests use real DB or mocks.

**Step 6 — Key dependencies and external services**
- Read `package.json` deps, `requirements.txt`, `go.mod`, or equivalent.
- List notable libraries by role (framework, ORM, auth, queue, mailer, payments, storage, observability).
- Cross-reference with `.env.example` / `.env.sample` to identify external services.

**Step 7 — Schema overview (only if database: true)**
- For Prisma: read `prisma/schema.prisma` — list model names and key relations.
- For EF Core: list entity class names from the Domain project.
- For SQLAlchemy: grep for `class.*Base` in models directory.
- For TypeORM/GORM/Hibernate/ActiveRecord: grep for entity/model annotations.
- List migration directory and count of existing migrations.

**Step 8 — Available scripts**
- For node: read `scripts` section of `package.json`.
- For python: read `[tool.poetry.scripts]` in `pyproject.toml` or list `Makefile` targets.
- For dotnet: note standard `dotnet` commands plus any `Makefile` targets.
- For go/java/ruby: list `Makefile` targets if present, otherwise note standard commands.

---

### Output files

Write all files to `.claude/dev-workflow-context/`. Omit any section where nothing was found.

---

**File 1: `.claude/dev-workflow-context/read-codebase.md`**

Loaded by every agent via the `read-codebase` skill. Contains the actual layer map, request flow, auth, response contracts, and test layout for this project.

```markdown
# This project — layer map
> Generated by /dev-workflow:init. Re-run to refresh.

## Layers
| Path | Layer | Purpose |
|------|-------|---------|
| src/api/         | presentation   | Express routes and controllers |
| src/services/    | application    | Business logic and use cases   |
| src/repositories/| infrastructure | DB access via Prisma            |
| src/entities/    | domain         | TypeORM entity definitions      |
| src/middleware/  | cross-cutting  | Auth, error handler, logging    |
| tests/           | test           | Jest unit and integration tests |

## Entry point
- File: `src/index.ts`
- Bootstrap order: helmet → cors → auth middleware → routes → errorHandler

## Request flow
`src/api/routes.ts` → Controller → Service → Repository → DB

## Auth
- Mechanism: JWT Bearer token
- File: `src/middleware/auth.ts`
- Applied: globally — opt-out with `@Public()` decorator on handler

## Response contracts
- Success: `{ data: T, meta?: { page, limit, total } }`
- Error: `{ error: { code: string, message: string } }`
- Dates: ISO 8601 UTC strings
- Field naming: camelCase in responses, snake_case in DB columns

## Test layout
- Directory: `tests/`
- File pattern: `*.test.ts`
- Base helper: `tests/helpers/setup.ts`
- DB in tests: in-memory SQLite (no real DB in unit tests)
```

---

**File 2: `.claude/dev-workflow-context/run-terminal.md`**

Loaded by every agent via the `run-terminal` skill. Contains the actual scripts and commands available in this project.

```markdown
# This project — available scripts
> Generated by /dev-workflow:init. Re-run to refresh.

## npm / pnpm scripts
| Script | Command |
|--------|---------|
| `pnpm dev` | Start dev server with hot reload |
| `pnpm build` | Compile TypeScript |
| `pnpm test` | Run Jest |
| `pnpm test:watch` | Run Jest in watch mode |
| `pnpm lint` | ESLint |
| `pnpm migrate` | Run Prisma migrations (dev) |
| `pnpm migrate:deploy` | Apply migrations (prod — requires human approval) |

## Makefile targets (if present)
| Target | Purpose |
|--------|---------|
| `make up` | Start Docker services |
| `make down` | Stop Docker services |
```

---

**File 3: `.claude/dev-workflow-context/database-conventions.md`** *(only if database: true)*

Loaded by agents that use the `database-conventions` skill. Contains the actual schema and migration state for this project.

```markdown
# This project — schema
> Generated by /dev-workflow:init. Re-run to refresh.

## Models / Tables
| Model | Key fields | Relations |
|-------|-----------|-----------|
| User | id, email, role, createdAt | has many Orders |
| Order | id, userId, status, total | belongs to User, has many OrderItems |
| OrderItem | id, orderId, productId, qty, price | belongs to Order, Product |
| Product | id, name, price, stock | has many OrderItems |

## Migrations
- Location: `prisma/migrations/`
- Count: 8 migrations present
- Latest: `20240310_add_product_stock`

## Key relations
- orders.userId → users.id (cascade delete)
- order_items.orderId → orders.id
- order_items.productId → products.id
```

---

6. Confirm the written config to the user and tell them:
- All skills (run-terminal, database-conventions, etc.) will now adapt to this stack automatically
- If the scan ran, agents load the context files automatically via their skills — no extra steps needed:
  - `read-codebase` ← `.claude/dev-workflow-context/read-codebase.md` (layer map, auth, response contracts)
  - `run-terminal` ← `.claude/dev-workflow-context/run-terminal.md` (actual project scripts)
  - `database-conventions` ← `.claude/dev-workflow-context/database-conventions.md` (schema, migrations)
- Re-run `/dev-workflow:init` at any time to reconfigure or refresh the context
- Commit `.claude/dev-workflow.json` and `.claude/dev-workflow-context/` so the whole team shares the same context
- If hooks were enabled, the post-edit check runs silently on success and prints errors on failure
