#!/bin/bash
# Outputs stack-specific terminal conventions as markdown.
# Called by the run-terminal skill via !`command` injection.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-stack.sh"

cat << EOF
## Stack: $STACK ${STACK_DETAIL:+($STACK_DETAIL)}
EOF

case "$STACK" in
  node)
    PKG=$PACKAGE_MANAGER
    cat << EOF

### Build & run
\`\`\`bash
$PKG run build
$PKG run dev        # or start
$PKG run lint
\`\`\`

### Tests
\`\`\`bash
$PKG run test                          # all tests
$PKG run test -- --testPathPattern=X  # single file (jest)
$PKG run test -- --watch              # watch mode
\`\`\`

### Package management
\`\`\`bash
$PKG install
$PKG add <package>
$PKG remove <package>
\`\`\`

### Rules
- Never run \`rm -rf node_modules\` without asking
- Prefer \`$PKG run\` over calling binaries directly
- Check \`package.json\` scripts before assuming command names
EOF
    ;;

  dotnet)
    SLN=${SOLUTION_FILE:-"*.sln"}
    cat << EOF

### Build & run
\`\`\`bash
dotnet build $SLN
dotnet run --project src/<ProjectName>.Api
\`\`\`

### Tests
\`\`\`bash
dotnet test $SLN                                      # all tests
dotnet test $SLN --filter "FullyQualifiedName~MyTest" # single test class
\`\`\`

### Migrations (EF Core)
\`\`\`bash
# Add migration (safe — creates files only, never modifies DB)
dotnet ef migrations add "MigrationName" --context <DbContext> --project src/<Infra> --startup-project src/<Api>

# Apply migration — NEVER run without explicit human consent
# dotnet ef database update ...
\`\`\`

### Rules
- Never run \`dotnet ef database update\` without explicit human approval
- Always target the correct \`--context\` for EF commands
- Build before running tests to catch compile errors first
EOF
    ;;

  python)
    PKG=$PACKAGE_MANAGER
    cat << EOF

### Build & run
\`\`\`bash
$PKG run dev      # or: python -m uvicorn app.main:app --reload
$PKG run lint     # or: flake8 / ruff
\`\`\`

### Tests
\`\`\`bash
pytest                          # all tests
pytest tests/test_specific.py  # single file
pytest -k "test_name"          # single test
pytest --cov                    # with coverage
\`\`\`

### Package management
\`\`\`bash
$PKG add <package>     # or: pip install <package>
$PKG remove <package>
\`\`\`

### Rules
- Always run inside the virtualenv
- Do not modify requirements.txt manually — use the package manager
- Check for \`Makefile\` targets before assuming command names
EOF
    ;;

  go)
    cat << EOF

### Build & run
\`\`\`bash
go build ./...
go run cmd/main.go    # or wherever the entrypoint is
go vet ./...
\`\`\`

### Tests
\`\`\`bash
go test ./...                  # all tests
go test ./pkg/mypackage/...    # single package
go test -run TestFunctionName  # single test
go test -cover ./...           # with coverage
\`\`\`

### Rules
- Always run \`go mod tidy\` after adding or removing dependencies
- Use \`go vet\` before committing
EOF
    ;;

  java)
    cat << EOF

### Build & run ($PACKAGE_MANAGER)
\`\`\`bash
$([ "$PACKAGE_MANAGER" = "maven" ] && echo "mvn clean install
mvn spring-boot:run    # if Spring Boot" || echo "gradle build
gradle bootRun         # if Spring Boot")
\`\`\`

### Tests
\`\`\`bash
$([ "$PACKAGE_MANAGER" = "maven" ] && echo "mvn test
mvn test -Dtest=MyTestClass" || echo "gradle test
gradle test --tests MyTestClass")
\`\`\`

### Rules
- Do not modify build files without understanding the dependency tree
- Run tests before pushing
EOF
    ;;

  ruby)
    cat << EOF

### Build & run
\`\`\`bash
bundle install
bundle exec rails server    # or: bundle exec rackup
bundle exec rubocop         # lint
\`\`\`

### Tests
\`\`\`bash
bundle exec rspec                          # all tests
bundle exec rspec spec/models/user_spec.rb # single file
\`\`\`

### Rules
- Always use \`bundle exec\` to run commands
- Do not modify Gemfile.lock manually
EOF
    ;;

  *)
    cat << EOF

Stack not configured or not recognized.
Run \`/dev-workflow:init\` to configure this project.

General rules:
- Check for a Makefile, package.json, or README for project-specific commands
- Never delete files or run destructive commands without confirmation
EOF
    ;;
esac
