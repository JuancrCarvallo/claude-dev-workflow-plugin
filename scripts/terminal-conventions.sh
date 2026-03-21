#!/bin/bash
# Outputs stack-specific terminal conventions as markdown.
# Called by the run-terminal skill via !`command` injection.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-stack.sh"

# ─── Per-stack conventions ───────────────────────────────────────────────────
_emit_terminal_conventions() {
  local name="$1" role="$2" detail="$3" pm="$4" tf="$5"

  case "$name" in
    node)
      local PKG="${pm:-npm}"
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

    php)
      cat << EOF

### Build & run
\`\`\`bash
composer install
EOF
      case "$detail" in
        laravel)
          cat << EOF
php artisan serve               # dev server
php artisan route:list          # list all routes
php artisan make:controller X   # scaffold controller
php artisan make:model X -m     # scaffold model + migration
php artisan tinker              # REPL
\`\`\`

### Tests
\`\`\`bash
php artisan test                          # all tests
php artisan test --filter=TestClassName   # single class
./vendor/bin/phpunit                      # direct PHPUnit
EOF
      if [ "$tf" = "pest" ]; then
        cat << EOF
./vendor/bin/pest                         # Pest runner
./vendor/bin/pest --filter=test_name      # single test
EOF
      fi
      cat << EOF
\`\`\`

### Migrations
\`\`\`bash
php artisan migrate                # apply pending (NEVER in prod without consent)
php artisan migrate:status         # check status
php artisan make:migration name    # create migration file (safe)
\`\`\`

### Cache & config
\`\`\`bash
php artisan config:clear
php artisan cache:clear
php artisan view:clear
\`\`\`
EOF
          ;;
        symfony)
          cat << EOF
php bin/console server:start    # dev server (Symfony < 5)
symfony serve                   # Symfony CLI dev server
php bin/console debug:router    # list all routes
\`\`\`

### Tests
\`\`\`bash
./vendor/bin/phpunit                      # all tests
./vendor/bin/phpunit --filter=TestClass   # single class
\`\`\`

### Migrations (Doctrine)
\`\`\`bash
php bin/console doctrine:migrations:migrate   # apply (NEVER in prod without consent)
php bin/console doctrine:migrations:diff      # generate migration from entity diff
php bin/console doctrine:migrations:status    # check status
\`\`\`

### Cache
\`\`\`bash
php bin/console cache:clear
\`\`\`
EOF
          ;;
        *)
          cat << EOF
php -S localhost:8000 -t public   # built-in dev server
\`\`\`

### Tests
\`\`\`bash
./vendor/bin/phpunit                      # all tests
./vendor/bin/phpunit --filter=TestClass   # single class
\`\`\`
EOF
          ;;
      esac
      cat << EOF

### Package management
\`\`\`bash
composer install
composer require <package>
composer remove <package>
composer dump-autoload
\`\`\`

### Rules
- Never run \`composer update\` without asking — it updates all dependencies
- Prefer \`composer require\` over editing composer.json manually
- Always run \`composer dump-autoload\` after PSR-4 namespace changes
- Never run destructive artisan commands (migrate:fresh, db:wipe) without consent
EOF
      ;;

    dotnet)
      local SLN="${SOLUTION_FILE:-*.sln}"
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
      local PKG="${pm:-pip}"
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

### Build & run ($pm)
\`\`\`bash
$([ "$pm" = "maven" ] && echo "mvn clean install
mvn spring-boot:run    # if Spring Boot" || echo "gradle build
gradle bootRun         # if Spring Boot")
\`\`\`

### Tests
\`\`\`bash
$([ "$pm" = "maven" ] && echo "mvn test
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

    js-assets)
      cat << EOF

### Frontend assets (no build tool)
- No package manager — scripts are loaded directly via \`<script>\` tags
- To add a library: download or use a CDN, place in \`public/js/\` or equivalent
- jQuery: check the version in the script tag or file header

### Rules
- Do not assume a build step exists — files are served as-is
- Test changes by refreshing the browser
- Check for minified vs source files before editing
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
}

# ─── Main output ─────────────────────────────────────────────────────────────
if [ "$STACK_COUNT" -gt 1 ]; then
  echo "## Monolith — $STACK_COUNT stacks detected"
  for i in $(seq 0 $((STACK_COUNT - 1))); do
    _name_var="STACK_${i}_NAME"
    _role_var="STACK_${i}_ROLE"
    _detail_var="STACK_${i}_DETAIL"
    _pm_var="STACK_${i}_PACKAGE_MANAGER"
    _tf_var="STACK_${i}_TEST_FRAMEWORK"
    echo ""
    echo "---"
    echo "## Stack $((i + 1)): ${!_name_var} ${!_detail_var:+(${!_detail_var})} | Role: ${!_role_var}"
    _emit_terminal_conventions "${!_name_var}" "${!_role_var}" "${!_detail_var}" "${!_pm_var}" "${!_tf_var}"
  done
else
  cat << EOF
## Stack: $STACK ${STACK_DETAIL:+($STACK_DETAIL)}
EOF
  _emit_terminal_conventions "$STACK" "" "$STACK_DETAIL" "$PACKAGE_MANAGER" "$TEST_FRAMEWORK"
fi

# Inject project-specific scripts generated by /dev-workflow:init
CONTEXT_FILE=".claude/dev-workflow-context/run-terminal.md"
if [ -f "$CONTEXT_FILE" ]; then
  echo ""
  echo "---"
  cat "$CONTEXT_FILE"
fi
