#!/bin/bash
# Outputs stack-specific file writing conventions as markdown.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-stack.sh"

# ─── Per-stack conventions ───────────────────────────────────────────────────
_emit_write_conventions() {
  local name="$1" role="$2" detail="$3"

  case "$name" in
    node)
      cat << EOF
## File conventions: $name ${detail:+($detail)}

- File names: \`kebab-case.ts\` for modules, \`PascalCase.ts\` for classes
- One class or one logical unit per file
- Imports: external packages first, then internal — use path aliases if configured (\`@/...\`)
- Exports: named exports preferred over default exports
- Types: colocate with the module or place in \`src/types/\`
- No \`console.log\` in production code — use the project logger
- Use \`Write\` tool to create new files — do not use Bash heredocs
EOF
      ;;

    php)
      cat << EOF
## File conventions: PHP ${detail:+($detail)}

- File names: \`PascalCase.php\` — must match class name (PSR-4)
- One class per file
- Namespace matches directory structure (PSR-4 autoloading)
- Use statements at top: one per line, alphabetized
- Visibility: always declare explicit visibility (public/protected/private)
- Type hints: use parameter and return type declarations
- No \`echo\` or \`var_dump\` in production code — use the project logger
EOF
      case "$detail" in
        laravel)
          cat << EOF
- Controllers: \`app/Http/Controllers/\` — extend base Controller
- Models: \`app/Models/\` — extend Eloquent Model
- Requests: \`app/Http/Requests/\` — extend FormRequest for validation
- Services: \`app/Services/\` — plain PHP classes for business logic
- Blade views: \`resources/views/\` — use \`.blade.php\` extension
- Migrations: \`database/migrations/\` — timestamped, never edit existing ones
EOF
          ;;
        symfony)
          cat << EOF
- Controllers: \`src/Controller/\` — extend AbstractController
- Entities: \`src/Entity/\` — Doctrine managed classes
- Repositories: \`src/Repository/\` — extend ServiceEntityRepository
- Services: \`src/Service/\` — registered via services.yaml or autowiring
- Templates: \`templates/\` — Twig files (\`.html.twig\`)
EOF
          ;;
      esac
      cat << EOF
- Use \`Write\` tool to create new files — do not use Bash heredocs
EOF
      ;;

    dotnet)
      cat << EOF
## File conventions: dotnet

- Namespace matches folder structure: \`Company.Project.Layer.Subfolder\`
- One class per file; filename matches class name exactly
- Place files in the correct project layer:
  - Entities/enums -> *.Domain
  - Handlers/DTOs/validators -> *.Application
  - EF config/repositories -> *.Infrastructure
  - Controllers -> *.Api
- Using directives: remove unused ones — do not leave dead usings
- Use \`Write\` or \`Edit\` tools — do not use Bash to create files
EOF
      ;;

    python)
      cat << EOF
## File conventions: python

- File names: \`snake_case.py\`
- Class names: \`PascalCase\`
- Keep modules focused — one responsibility per file
- Imports: stdlib -> third-party -> local (PEP8)
- Use type hints on all function signatures
- No bare \`except:\` — always catch specific exceptions
- Use \`Write\` tool to create new files
EOF
      ;;

    go)
      cat << EOF
## File conventions: go

- File names: \`snake_case.go\`
- Package name matches directory name (lowercase, no underscores)
- Exported names: \`PascalCase\`; unexported: \`camelCase\`
- Keep packages small and focused
- Error handling: always check and wrap errors with context (\`fmt.Errorf("...: %w", err)\`)
- Use \`Write\` tool to create new files
EOF
      ;;

    java)
      cat << EOF
## File conventions: java

- File names: \`PascalCase.java\`; must match class name
- Package structure matches directory structure
- One top-level class per file
- Annotations first, then class declaration
- Use constructor injection over field injection
- Use \`Write\` tool to create new files
EOF
      ;;

    ruby)
      cat << EOF
## File conventions: ruby

- File names: \`snake_case.rb\`; class names: \`PascalCase\`
- Follow Rails conventions — don't fight the framework
- Keep controllers thin — business logic in service objects
- Use \`Write\` tool to create new files
EOF
      ;;

    js-assets)
      cat << EOF
## File conventions: JavaScript assets (no build tool)

- File names: \`kebab-case.js\` or match existing project convention
- No modules — scripts are loaded via \`<script>\` tags (order matters)
- Wrap code in IIFEs or use jQuery's \`$(document).ready()\` to avoid globals
- Keep files small and focused on one page or feature
- Use \`Write\` tool to create new files
EOF
      ;;

    *)
      echo "Stack not configured. Run \`/dev-workflow:init\` to configure."
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
    _emit_write_conventions "${!_name_var}" "${!_role_var}" "${!_detail_var}"
  done
else
  _emit_write_conventions "$STACK" "" "$STACK_DETAIL"
fi

cat << EOF

## Universal rules
- Edit existing files with \`Edit\` tool — never rewrite a whole file to change one line
- Do not create files unless explicitly required by the task
- Do not add comments to code you didn't change
- Do not add error handling for scenarios that can't happen
- Never leave debug code, TODOs, or commented-out blocks in production code
EOF
