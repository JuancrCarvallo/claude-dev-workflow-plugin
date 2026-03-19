#!/bin/bash
# Outputs stack-specific codebase navigation conventions as markdown.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-stack.sh"

cat << EOF
## Stack: $STACK ${STACK_DETAIL:+($STACK_DETAIL)} | Type: $TYPE
EOF

case "$STACK" in
  node)
    cat << EOF

### Typical structure
\`\`\`
src/
  controllers/ | routes/   ← entry points
  services/                ← business logic
  models/ | entities/      ← data models
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

  dotnet)
    cat << EOF

### Typical structure (Clean/Layered)
\`\`\`
src/
  *.Api/           ← controllers, middleware, DI bootstrapping
  *.Application/   ← handlers, DTOs, validators, mapping
  *.Domain/        ← entities, enums, exceptions
  *.Infrastructure/← DbContext, repositories, external clients
  *.Test/          ← unit and functional tests
\`\`\`

### How to navigate
- Entry point: \`Program.cs\` or \`Startup.cs\` in *.Api
- Find a handler: Grep for the command/query class name
- Find an entity: look in *.Domain/Entities/
- Find a controller: look in *.Api/Controllers/
- Request flow: Controller → Mediator.Send() → Handler → Infrastructure
EOF
    ;;

  python)
    cat << EOF

### Typical structure
\`\`\`
app/ | src/
  api/ | routes/    ← entry points
  services/         ← business logic
  models/           ← data models / ORM entities
  schemas/          ← Pydantic / serialization
  core/ | config/   ← settings, dependencies
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
cmd/          ← entrypoints (main packages)
internal/
  handler/    ← HTTP handlers
  service/    ← business logic
  repository/ ← DB access
  model/      ← domain types
pkg/          ← shared/reusable packages
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
  controller/   ← REST endpoints
  service/      ← business logic
  repository/   ← data access (JPA)
  model/entity/ ← domain entities
  dto/          ← request/response shapes
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

  *)
    echo "Stack not configured. Run \`/dev-workflow:init\` to configure."
    ;;
esac

cat << EOF

## Universal rules
- Max 10 files read per hop — target affected modules only
- Read interfaces and contracts before implementations
- Prefer Grep over reading entire directories
- When unsure where something lives, Grep for the class/function name first
EOF
