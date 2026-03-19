#!/bin/bash
# Outputs stack-specific file writing conventions as markdown.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-stack.sh"

case "$STACK" in
  node)
    cat << EOF
## File conventions: $STACK ${STACK_DETAIL:+($STACK_DETAIL)}

- File names: \`kebab-case.ts\` for modules, \`PascalCase.ts\` for classes
- One class or one logical unit per file
- Imports: external packages first, then internal — use path aliases if configured (\`@/...\`)
- Exports: named exports preferred over default exports
- Types: colocate with the module or place in \`src/types/\`
- No \`console.log\` in production code — use the project logger
- Use \`Write\` tool to create new files — do not use Bash heredocs
EOF
    ;;

  dotnet)
    cat << EOF
## File conventions: $STACK

- Namespace matches folder structure: \`Company.Project.Layer.Subfolder\`
- One class per file; filename matches class name exactly
- Place files in the correct project layer:
  - Entities/enums → *.Domain
  - Handlers/DTOs/validators → *.Application
  - EF config/repositories → *.Infrastructure
  - Controllers → *.Api
- Using directives: remove unused ones — do not leave dead usings
- Use \`Write\` or \`Edit\` tools — do not use Bash to create files
EOF
    ;;

  python)
    cat << EOF
## File conventions: $STACK

- File names: \`snake_case.py\`
- Class names: \`PascalCase\`
- Keep modules focused — one responsibility per file
- Imports: stdlib → third-party → local (PEP8)
- Use type hints on all function signatures
- No bare \`except:\` — always catch specific exceptions
- Use \`Write\` tool to create new files
EOF
    ;;

  go)
    cat << EOF
## File conventions: $STACK

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
## File conventions: $STACK

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
## File conventions: $STACK

- File names: \`snake_case.rb\`; class names: \`PascalCase\`
- Follow Rails conventions — don't fight the framework
- Keep controllers thin — business logic in service objects
- Use \`Write\` tool to create new files
EOF
    ;;

  *)
    echo "Stack not configured. Run \`/dev-workflow:init\` to configure."
    ;;
esac

cat << EOF

## Universal rules
- Edit existing files with \`Edit\` tool — never rewrite a whole file to change one line
- Do not create files unless explicitly required by the task
- Do not add comments to code you didn't change
- Do not add error handling for scenarios that can't happen
- Never leave debug code, TODOs, or commented-out blocks in production code
EOF
