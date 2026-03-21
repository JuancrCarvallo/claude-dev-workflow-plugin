#!/bin/bash
# Post-edit hook: runs a lightweight build/syntax check after file writes.
# Outputs nothing on success. Prints errors to stderr on failure.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-stack.sh"

# Only check if a source file was edited (passed as $1 by the hook runner, optional)
EDITED_FILE="${1:-}"

# ─── Multi-stack: dispatch by file extension when possible ──────────────────
if [ -n "$EDITED_FILE" ] && [ "$STACK_COUNT" -gt 1 ]; then
  case "$EDITED_FILE" in
    *.php|*.blade.php)
      # PHP syntax check
      php -l "$EDITED_FILE" 2>&1 | grep -v "No syntax errors"
      PHP_EXIT=${PIPESTATUS[0]}
      # PHPStan if available
      if [ "$PHP_EXIT" -eq 0 ] && command -v ./vendor/bin/phpstan &>/dev/null; then
        ./vendor/bin/phpstan analyse "$EDITED_FILE" --no-progress 2>&1
        exit $?
      fi
      exit $PHP_EXIT
      ;;
    *.ts|*.tsx)
      if [ -f "tsconfig.json" ]; then
        npx --no-install tsc --noEmit 2>&1
        exit $?
      fi
      ;;
    *.js|*.jsx)
      if [ -f ".eslintrc" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ]; then
        npx --no-install eslint "$EDITED_FILE" 2>&1
        exit $?
      fi
      ;;
    *.py)
      if command -v ruff &>/dev/null; then
        ruff check "$EDITED_FILE" 2>&1
        exit $?
      elif command -v flake8 &>/dev/null; then
        flake8 "$EDITED_FILE" 2>&1
        exit $?
      else
        python3 -m py_compile "$EDITED_FILE" 2>&1
        exit $?
      fi
      ;;
    *.cs)
      dotnet build --no-restore -v quiet 2>&1
      exit $?
      ;;
    *.go)
      go build ./... 2>&1
      exit $?
      ;;
    *.java)
      if [ -f "pom.xml" ]; then
        mvn compile -q 2>&1
      elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        ./gradlew compileJava -q 2>&1
      fi
      exit $?
      ;;
    *.rb)
      ruby -c "$EDITED_FILE" 2>&1
      exit $?
      ;;
  esac
  # Unknown extension in monolith — skip silently
  exit 0
fi

# ─── Single-stack: original behavior ────────────────────────────────────────
case "$STACK" in
  node)
    # Type-check if TypeScript is configured
    if [ -f "tsconfig.json" ]; then
      npx --no-install tsc --noEmit 2>&1
      exit $?
    fi
    # JS-only: try a quick lint if eslint is present
    if [ -f ".eslintrc" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ]; then
      if [ -n "$EDITED_FILE" ]; then
        npx --no-install eslint "$EDITED_FILE" 2>&1
      else
        npx --no-install eslint . --max-warnings=0 2>&1
      fi
      exit $?
    fi
    ;;

  php)
    if [ -n "$EDITED_FILE" ] && [[ "$EDITED_FILE" == *.php ]]; then
      php -l "$EDITED_FILE" 2>&1 | grep -v "No syntax errors"
      PHP_EXIT=${PIPESTATUS[0]}
      if [ "$PHP_EXIT" -eq 0 ] && command -v ./vendor/bin/phpstan &>/dev/null; then
        ./vendor/bin/phpstan analyse "$EDITED_FILE" --no-progress 2>&1
        exit $?
      fi
      exit $PHP_EXIT
    fi
    # Full project check
    if command -v ./vendor/bin/phpstan &>/dev/null; then
      ./vendor/bin/phpstan analyse --no-progress 2>&1
      exit $?
    fi
    ;;

  dotnet)
    dotnet build --no-restore -v quiet 2>&1
    exit $?
    ;;

  python)
    # Use ruff if available, fallback to flake8, fallback to py_compile
    if command -v ruff &>/dev/null; then
      if [ -n "$EDITED_FILE" ]; then
        ruff check "$EDITED_FILE" 2>&1
      else
        ruff check . 2>&1
      fi
      exit $?
    elif command -v flake8 &>/dev/null; then
      if [ -n "$EDITED_FILE" ]; then
        flake8 "$EDITED_FILE" 2>&1
      else
        flake8 . 2>&1
      fi
      exit $?
    else
      # Last resort: syntax check changed file only
      if [ -n "$EDITED_FILE" ] && [[ "$EDITED_FILE" == *.py ]]; then
        python3 -m py_compile "$EDITED_FILE" 2>&1
        exit $?
      fi
    fi
    ;;

  go)
    go build ./... 2>&1
    exit $?
    ;;

  java)
    if [ -f "pom.xml" ]; then
      mvn compile -q 2>&1
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
      ./gradlew compileJava -q 2>&1
    fi
    exit $?
    ;;

  ruby)
    if [ -n "$EDITED_FILE" ] && [[ "$EDITED_FILE" == *.rb ]]; then
      ruby -c "$EDITED_FILE" 2>&1
      exit $?
    fi
    ;;
esac

exit 0
