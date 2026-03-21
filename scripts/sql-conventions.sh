#!/bin/bash
# Outputs ORM/SQL conventions based on project config.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-stack.sh"

if [ "$DATABASE" != "true" ]; then
  echo "No database configured for this project."
  exit 0
fi

cat << EOF
## Database: $DB_ENGINE
EOF

# ─── Per-ORM conventions ────────────────────────────────────────────────────
_emit_orm_conventions() {
  local orm="$1"

  case "$orm" in
    prisma)
      cat << EOF

### Prisma conventions
- Schema lives in \`prisma/schema.prisma\`
- Never write raw SQL — use Prisma Client methods
- Use \`prisma.\$transaction()\` for operations that must be atomic
- Never expose the Prisma client directly — wrap in a repository or service
- Migrations: \`prisma migrate dev --name <name>\` (development only)
- Never run \`prisma migrate deploy\` without explicit human consent

### Safety rules
- Always use parameterized queries when using \`\$queryRaw\` or \`\$executeRaw\`
- Never interpolate user input into \`\$queryRaw\` template literals
- Filter by ownership before returning records (prevent IDOR)
EOF
      ;;

    typeorm)
      cat << EOF

### TypeORM conventions
- Use Repository pattern — inject via \`@InjectRepository(Entity)\`
- Use QueryBuilder for complex queries — never string-concatenate SQL
- Transactions: use \`EntityManager\` or \`DataSource.transaction()\`
- Migrations live in \`src/migrations/\` — run with \`typeorm migration:run\`
- Never run migrations in production without explicit human consent

### Safety rules
- Always use parameterized queries: \`.where("field = :value", { value })\`
- Never use \`.where(\`field = \${userInput}\`)\` — SQL injection risk
EOF
      ;;

    sequelize)
      cat << EOF

### Sequelize conventions
- Define models with associations in \`src/models/\`
- Use \`where: { field: value }\` objects — never template-string SQL
- Transactions: \`sequelize.transaction()\`
- Migrations in \`src/migrations/\` — run with \`sequelize db:migrate\`

### Safety rules
- Never pass user input directly into \`where\` string clauses
- Use \`Op\` operators for complex conditions, not raw strings
EOF
      ;;

    eloquent)
      cat << EOF

### Eloquent conventions (Laravel)
- Models live in \`app/Models/\` — extend \`Illuminate\Database\Eloquent\Model\`
- Use Eloquent query builder: \`Model::where('field', value)->get()\`
- Never concatenate user input into \`whereRaw()\` or \`DB::raw()\` strings
- Relationships: define in model methods (\`hasMany\`, \`belongsTo\`, etc.)
- Transactions: \`DB::transaction(function () { ... })\`
- Migrations: \`php artisan make:migration name\` — timestamped, never edit existing
- Never run \`php artisan migrate:fresh\` or \`db:wipe\` without explicit human consent

### Safety rules
- Always use parameterized queries: \`->where('field', '=', \$value)\` or \`->whereRaw('field = ?', [\$value])\`
- Never: \`->whereRaw("field = '\$userInput'")\` — SQL injection risk
- Use \`\$fillable\` or \`\$guarded\` on every model to prevent mass assignment
- Filter by ownership before returning records (prevent IDOR)
- Use \`firstOrFail()\` / \`findOrFail()\` to avoid null dereferences
EOF
      ;;

    doctrine)
      cat << EOF

### Doctrine conventions (Symfony)
- Entities live in \`src/Entity/\` — managed by Doctrine ORM
- Use DQL (Doctrine Query Language) or QueryBuilder for complex queries
- Never concatenate user input into DQL strings
- Repositories: extend \`ServiceEntityRepository\` in \`src/Repository/\`
- Transactions: \`\$entityManager->wrapInTransaction(function () { ... })\`
- Migrations: \`php bin/console doctrine:migrations:diff\` to generate, \`migrate\` to apply
- Never run migrations in production without explicit human consent

### Safety rules
- Always use named parameters: \`->where('e.field = :value')->setParameter('value', \$value)\`
- Never: \`->where("e.field = '\$userInput'")\` — SQL injection risk
- Use Doctrine lifecycle callbacks or event listeners, not raw SQL triggers
- Filter by ownership before returning records
EOF
      ;;

    sqlalchemy)
      cat << EOF

### SQLAlchemy conventions
- Use ORM-style queries: \`session.query(Model).filter_by(...)\`
- For complex queries: SQLAlchemy Core with bound parameters
- Never use f-strings or \`.format()\` to build SQL queries
- Session management: use dependency injection or context managers
- Migrations: Alembic — \`alembic revision --autogenerate -m "name"\`
- Never run \`alembic upgrade head\` in production without consent

### Safety rules
- Parameterize all raw SQL: \`text("SELECT * FROM t WHERE id = :id")\` with \`{"id": value}\`
EOF
      ;;

    efcore)
      cat << EOF

### EF Core conventions
- Use LINQ expressions — never string-interpolate into \`FromSqlRaw\`
- If raw SQL is needed: \`FromSqlRaw("SELECT ... WHERE Id = {0}", id)\` with positional params
- Transactions: \`dbContext.Database.BeginTransactionAsync()\`
- Migrations: \`dotnet ef migrations add "Name" --context <DbContext>\`
- NEVER run \`dotnet ef database update\` without explicit human consent
- Contexts: write only to the primary writable context — never to read-only external contexts

### Safety rules
- Never use \`FromSqlInterpolated\` with user input — use \`FromSqlRaw\` with parameters
- Always filter by ownership before returning records
EOF
      ;;

    gorm)
      cat << EOF

### GORM conventions
- Use struct conditions or named parameters — never raw string interpolation
- \`db.Where("name = ?", name)\` — always use \`?\` placeholders
- Transactions: \`db.Transaction(func(tx *gorm.DB) error {...})\`
- Migrations: AutoMigrate in dev only — use explicit migration files in production

### Safety rules
- Never: \`db.Where(fmt.Sprintf("name = '%s'", userInput))\`
- Always: \`db.Where("name = ?", userInput)\`
EOF
      ;;

    hibernate)
      cat << EOF

### Hibernate / JPA conventions
- Use Spring Data repositories for standard CRUD
- For custom queries: JPQL with named parameters (\`:param\`)
- Never concatenate user input into JPQL or SQL strings
- Transactions: \`@Transactional\` on service methods

### Safety rules
- Named parameters only: \`@Query("SELECT u FROM User u WHERE u.name = :name")\`
- Never: \`"SELECT * FROM users WHERE name = '" + name + "'"\`
EOF
      ;;

    activerecord)
      cat << EOF

### ActiveRecord conventions
- Use relation methods: \`.where(field: value)\` hash syntax
- For complex queries: Arel or parameterized strings \`.where("field = ?", value)\`
- Never interpolate user input: avoid \`.where("name = '\#{params[:name]}'")\`
- Transactions: \`ActiveRecord::Base.transaction do ... end\`
- Migrations: \`rails generate migration Name\` — never edit existing migrations

### Safety rules
- Always use hash conditions or \`?\` placeholders
- Sanitize before using in raw SQL with \`ActiveRecord::Base.sanitize_sql\`
EOF
      ;;

    *)
      cat << EOF

### General SQL safety rules
- Never interpolate user input into SQL strings
- Always use parameterized queries / prepared statements
- Wrap multi-step operations in transactions
- Never apply schema changes to production without explicit human consent
EOF
      ;;
  esac
}

# ─── Main output ─────────────────────────────────────────────────────────────
if [ "$STACK_COUNT" -gt 1 ]; then
  # Emit ORM conventions for each stack that has one
  for i in $(seq 0 $((STACK_COUNT - 1))); do
    _orm_var="STACK_${i}_ORM"
    _name_var="STACK_${i}_NAME"
    if [ -n "${!_orm_var}" ]; then
      echo ""
      echo "### ORM: ${!_orm_var} (${!_name_var})"
      _emit_orm_conventions "${!_orm_var}"
    fi
  done
else
  _emit_orm_conventions "$ORM"
fi

cat << EOF

## Universal DB rules
- Never expose DB credentials in code — use environment variables
- Always filter records by ownership/tenancy before returning to caller
- Avoid N+1 queries — use joins, includes, or batch fetching
- Never run destructive migrations (DROP, truncate) without explicit human consent
EOF

# Inject project-specific schema context generated by /dev-workflow:init
CONTEXT_FILE=".claude/dev-workflow-context/database-conventions.md"
if [ -f "$CONTEXT_FILE" ]; then
  echo ""
  echo "---"
  cat "$CONTEXT_FILE"
fi
