#!/bin/bash
# Outputs stack-specific codebase navigation conventions as markdown.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-stack.sh"

# ─── Per-stack conventions ───────────────────────────────────────────────────
_emit_stack_conventions() {
  local name="$1" role="$2" detail="$3"

  case "$name" in
    node)
      cat << EOF

### Typical structure
\`\`\`
src/
  controllers/ | routes/   <- entry points
  services/                <- business logic
  models/ | entities/      <- data models
  middleware/
  utils/ | helpers/
tests/ | __tests__/
\`\`\`

### How to navigate
- Entry point: \`src/index.ts\` or \`src/app.ts\`
- Routes: look for \`router\` usage or \`app.use()\` calls
- Find a handler: Grep for the route path string
- Find a model: Grep for the entity/model name
- Interfaces/types: \`src/types/\` or colocated \`.d.ts\` files
EOF
      ;;

    php)
      cat << EOF

### Typical structure
EOF
      case "$detail" in
        laravel)
          cat << EOF
\`\`\`
app/
  Http/Controllers/     <- request handlers
  Http/Middleware/       <- middleware stack
  Http/Requests/        <- form request validation
  Models/               <- Eloquent models
  Services/             <- business logic
  Providers/            <- service providers (DI)
routes/
  web.php               <- web routes
  api.php               <- API routes
resources/
  views/                <- Blade templates
  js/ | css/            <- frontend assets
database/
  migrations/           <- DB migrations
  seeders/              <- seed data
tests/
  Feature/              <- integration tests
  Unit/                 <- unit tests
\`\`\`

### How to navigate
- Entry point: \`routes/web.php\` and \`routes/api.php\`
- Find a controller: Grep for the class name or route path in \`routes/*.php\`
- Find a model: \`app/Models/<Name>.php\`
- Middleware: registered in \`app/Http/Kernel.php\` or \`bootstrap/app.php\` (Laravel 11+)
- Config: \`config/*.php\` — accessed via \`config('file.key')\`
- Views: \`resources/views/\` — Blade templates (\`.blade.php\`)
EOF
          ;;
        symfony)
          cat << EOF
\`\`\`
src/
  Controller/           <- request handlers
  Entity/               <- Doctrine entities
  Repository/           <- Doctrine repositories
  Service/              <- business logic
  Form/                 <- form types
config/
  routes.yaml           <- route definitions
  services.yaml         <- DI configuration
templates/              <- Twig templates
migrations/             <- Doctrine migrations
tests/
\`\`\`

### How to navigate
- Entry point: \`config/routes.yaml\` or annotations in Controller classes
- Find a controller: Grep for the route path or \`#[Route(...)]\` attribute
- Find an entity: \`src/Entity/<Name>.php\`
- Config: \`config/\` directory — YAML files
EOF
          ;;
        *)
          cat << EOF
\`\`\`
public/
  index.php             <- front controller
src/ | app/ | lib/
  Controllers/ | routes <- request handlers
  Models/               <- data models
  Services/             <- business logic
views/ | templates/
tests/
\`\`\`

### How to navigate
- Entry point: \`public/index.php\` or \`index.php\`
- Routes: Grep for route definitions or URL patterns
- Find a class: Grep for \`class ClassName\`
EOF
          ;;
      esac
      ;;

    dotnet)
      cat << EOF

### Typical structure (Clean/Layered)
\`\`\`
src/
  *.Api/           <- controllers, middleware, DI bootstrapping
  *.Application/   <- handlers, DTOs, validators, mapping
  *.Domain/        <- entities, enums, exceptions
  *.Infrastructure/<- DbContext, repositories, external clients
  *.Test/          <- unit and functional tests
\`\`\`

### How to navigate
- Entry point: \`Program.cs\` or \`Startup.cs\` in *.Api
- Find a handler: Grep for the command/query class name
- Find an entity: look in *.Domain/Entities/
- Find a controller: look in *.Api/Controllers/
- Request flow: Controller -> Mediator.Send() -> Handler -> Infrastructure
EOF
      ;;

    python)
      cat << EOF

### Typical structure
\`\`\`
app/ | src/
  api/ | routes/    <- entry points
  services/         <- business logic
  models/           <- data models / ORM entities
  schemas/          <- Pydantic / serialization
  core/ | config/   <- settings, dependencies
tests/
\`\`\`

### How to navigate
- Entry point: \`main.py\`, \`app.py\`, or \`wsgi.py\`
- Find a route: Grep for the path string or decorator
- Find a model: Grep for the class name in models/
EOF
      ;;

    go)
      cat << EOF

### Typical structure
\`\`\`
cmd/          <- entrypoints (main packages)
internal/
  handler/    <- HTTP handlers
  service/    <- business logic
  repository/ <- DB access
  model/      <- domain types
pkg/          <- shared/reusable packages
\`\`\`

### How to navigate
- Entry point: \`cmd/*/main.go\`
- Find a handler: Grep for the route path or handler function name
- Find a type: Grep for the struct name in internal/model/
EOF
      ;;

    java)
      cat << EOF

### Typical structure (Spring Boot)
\`\`\`
src/main/java/
  controller/   <- REST endpoints
  service/      <- business logic
  repository/   <- data access (JPA)
  model/entity/ <- domain entities
  dto/          <- request/response shapes
src/test/java/
\`\`\`

### How to navigate
- Entry point: class annotated with \`@SpringBootApplication\`
- Find an endpoint: Grep for \`@GetMapping\` / \`@PostMapping\` + path
- Find an entity: Grep for \`@Entity\` annotation
EOF
      ;;

    ruby)
      cat << EOF

### Typical structure (Rails)
\`\`\`
app/
  controllers/
  models/
  services/
  serializers/
config/routes.rb
spec/ | test/
\`\`\`

### How to navigate
- Routes: \`config/routes.rb\`
- Find a controller action: Grep for the action name in controllers/
- Find a model: \`app/models/<name>.rb\`
EOF
      ;;

    js-assets)
      cat << EOF

### Frontend assets (no build tool)
\`\`\`
public/js/ | resources/js/ | assets/js/ | static/js/
  *.js              <- JavaScript files (may include jQuery)
public/css/ | resources/css/
  *.css             <- Stylesheets
\`\`\`

### How to navigate
- Find a script: Grep for the function name or selector string
- jQuery selectors: Grep for \`$('\` or \`jQuery('\`
- Event bindings: Grep for \`.on(\` or \`.click(\` or \`.submit(\`
EOF
      ;;

    *)
      echo "Stack '$name' not configured. Run \`/dev-workflow:init\` to configure."
      ;;
  esac
}

# ─── Main output ─────────────────────────────────────────────────────────────
if [ "$STACK_COUNT" -gt 1 ]; then
  echo "## Monolith — $STACK_COUNT stacks detected"
  for i in $(seq 0 $((STACK_COUNT - 1))); do
    _name_var="STACK_${i}_NAME"
    _role_var="STACK_${i}_ROLE"
    _detail_var="STACK_${i}_DETAIL"
    echo ""
    echo "---"
    echo "## Stack $((i + 1)): ${!_name_var} ${!_detail_var:+(${!_detail_var})} | Role: ${!_role_var}"
    _emit_stack_conventions "${!_name_var}" "${!_role_var}" "${!_detail_var}"
  done
else
  cat << EOF
## Stack: $STACK ${STACK_DETAIL:+($STACK_DETAIL)} | Type: $TYPE
EOF
  _emit_stack_conventions "$STACK" "" "$STACK_DETAIL"
fi

cat << EOF

## Universal rules
- Max 10 files read per hop — target affected modules only
- Read interfaces and contracts before implementations
- Prefer Grep over reading entire directories
- When unsure where something lives, Grep for the class/function name first
EOF

# Inject project-specific layer context generated by /dev-workflow:init
CONTEXT_FILE=".claude/dev-workflow-context/read-codebase.md"
if [ -f "$CONTEXT_FILE" ]; then
  echo ""
  echo "---"
  cat "$CONTEXT_FILE"
fi
