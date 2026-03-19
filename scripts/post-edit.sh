#!/bin/bash
# Post-edit hook: runs a lightweight build/syntax check after file writes.
# Outputs nothing on success. Prints errors to stderr on failure.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/detect-stack.sh"

# Only check if a source file was edited (passed as $1 by the hook runner, optional)
EDITED_FILE="${1:-}"

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
