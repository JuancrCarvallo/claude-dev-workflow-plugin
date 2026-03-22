#!/bin/bash
# Reads .claude/dev-workflow.json if present.
# Falls back to auto-detection from project files.
# No external dependencies — pure bash (no jq required).
#
# Multi-stack support (monoliths):
#   When the config contains a "stacks" array, each entry is exported as
#   STACK_<i>_NAME, STACK_<i>_ROLE, STACK_<i>_DETAIL, STACK_<i>_PACKAGE_MANAGER,
#   STACK_<i>_TEST_FRAMEWORK, STACK_<i>_ORM.
#   STACK_COUNT holds the number of stacks.
#
#   For backward compatibility the first stack is also exported as the
#   flat STACK, STACK_DETAIL, PACKAGE_MANAGER, TEST_FRAMEWORK, ORM variables.

CONFIG=".claude/dev-workflow.json"

# ─── JSON helpers (pure bash — no jq) ────────────────────────────────────────
# These work on well-formatted JSON written by /dev-workflow:init.

# Extract a top-level string value.  Usage: _json_str "key" "file"
_json_str() {
  sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$2" | head -1
}

# Extract a top-level raw value (true/false/null/number).
_json_raw() {
  sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*\([a-z0-9.]*\).*/\1/p' "$2" | head -1
}

# Extract a string field from a single-line JSON snippet piped via stdin.
_field() {
  sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

# Extract each stack object from the "stacks" array as one line per object.
# Collapses multi-line JSON objects onto single lines for easy parsing.
_extract_stacks() {
  awk '
    /"stacks"[[:space:]]*:/ { in_arr=1; next }
    in_arr && /\{/  { in_obj=1; obj=""; next }
    in_arr && in_obj { gsub(/^[[:space:]]+/, ""); obj = obj " " $0 }
    in_arr && /\}/  { if (in_obj) { print obj; in_obj=0 } }
    in_arr && /\]/  { exit }
  ' "$1"
}

# ─── Helper: export one stack entry ──────────────────────────────────────────
_export_stack() {
  local idx="$1" name="$2" role="$3" detail="$4" pm="$5" tf="$6" orm="$7"
  export "STACK_${idx}_NAME=$name"
  export "STACK_${idx}_ROLE=$role"
  export "STACK_${idx}_DETAIL=$detail"
  export "STACK_${idx}_PACKAGE_MANAGER=$pm"
  export "STACK_${idx}_TEST_FRAMEWORK=$tf"
  export "STACK_${idx}_ORM=$orm"
}

# ─── Helper: auto-detect ORM for a given stack name ─────────────────────────
_detect_orm() {
  local stack="$1"
  case "$stack" in
    node)
      if [ -f "prisma/schema.prisma" ]; then echo "prisma"
      elif grep -q '"typeorm"' package.json 2>/dev/null; then echo "typeorm"
      elif grep -q '"sequelize"' package.json 2>/dev/null; then echo "sequelize"
      fi ;;
    php)
      if [ -f "artisan" ] || grep -q '"laravel/framework"' composer.json 2>/dev/null; then echo "eloquent"
      elif grep -q '"doctrine/orm"' composer.json 2>/dev/null; then echo "doctrine"
      fi ;;
    python)
      if grep -q 'sqlalchemy' requirements.txt 2>/dev/null; then echo "sqlalchemy"
      elif grep -q 'sqlalchemy' pyproject.toml 2>/dev/null; then echo "sqlalchemy"
      fi ;;
    dotnet) echo "efcore" ;;
    go)
      if [ -f "go.mod" ] && grep -q 'gorm' go.mod 2>/dev/null; then echo "gorm"; fi ;;
    ruby) echo "activerecord" ;;
    java)
      if grep -q 'hibernate' pom.xml 2>/dev/null || grep -q 'hibernate' build.gradle 2>/dev/null || grep -q 'hibernate' build.gradle.kts 2>/dev/null; then echo "hibernate"; fi ;;
  esac
}

# ─── Read from config ────────────────────────────────────────────────────────
if [ -f "$CONFIG" ]; then

  if grep -q '"stacks"' "$CONFIG"; then
    # ── Multi-stack (monolith) config ──
    STACK_COUNT=0
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      _name=$(echo "$line" | _field "name")
      _role=$(echo "$line" | _field "role")
      _detail=$(echo "$line" | _field "stack_detail")
      _pm=$(echo "$line" | _field "package_manager")
      _tf=$(echo "$line" | _field "test_framework")
      _orm=$(echo "$line" | _field "orm")
      _export_stack "$STACK_COUNT" "$_name" "$_role" "$_detail" "$_pm" "$_tf" "$_orm"
      STACK_COUNT=$((STACK_COUNT + 1))
    done < <(_extract_stacks "$CONFIG")

    # Flat aliases point to the first stack for backward compat
    STACK="$STACK_0_NAME"
    STACK_DETAIL="$STACK_0_DETAIL"
    PACKAGE_MANAGER="$STACK_0_PACKAGE_MANAGER"
    TEST_FRAMEWORK="$STACK_0_TEST_FRAMEWORK"
    ORM="$STACK_0_ORM"

  else
    # ── Single-stack config (original format) ──
    STACK_COUNT=1
    STACK=$(_json_str "stack" "$CONFIG")
    TYPE=$(_json_str "type" "$CONFIG")
    STACK_DETAIL=$(_json_str "stack_detail" "$CONFIG")
    PACKAGE_MANAGER=$(_json_str "package_manager" "$CONFIG")
    TEST_FRAMEWORK=$(_json_str "test_framework" "$CONFIG")
    SOLUTION_FILE=$(_json_str "solution_file" "$CONFIG")
    ORM=$(_json_str "orm" "$CONFIG")

    _export_stack 0 "$STACK" "$TYPE" "$STACK_DETAIL" "$PACKAGE_MANAGER" "$TEST_FRAMEWORK" "$ORM"
  fi

  DATABASE=$(_json_raw "database" "$CONFIG")
  DB_ENGINE=$(_json_str "db_engine" "$CONFIG")
  TASK_TRACKER=$(_json_str "task_tracker" "$CONFIG")
  BASE_BRANCH=$(_json_str "base_branch" "$CONFIG")
  [ -z "$BASE_BRANCH" ] && BASE_BRANCH="dev"
  BRANCH_PREFIX=$(_json_str "branch_prefix" "$CONFIG")
  TYPE=$(_json_str "type" "$CONFIG")

else
  # ─── Auto-detect from project files ──────────────────────────────────────
  STACK_COUNT=0

  # --- Backend detection ---
  if [ -f "composer.json" ]; then
    _name="php"
    _pm="composer"
    _detail=""
    if [ -f "artisan" ] || grep -q '"laravel/framework"' composer.json 2>/dev/null; then
      _detail="laravel"
    elif grep -q '"symfony/framework-bundle"' composer.json 2>/dev/null; then
      _detail="symfony"
    fi
    _tf=$(grep -q '"phpunit/phpunit"\|"pestphp/pest"' composer.json 2>/dev/null && (grep -q '"pestphp/pest"' composer.json 2>/dev/null && echo "pest" || echo "phpunit") || echo "phpunit")
    _orm=$(_detect_orm php)
    _export_stack "$STACK_COUNT" "$_name" "backend" "$_detail" "$_pm" "$_tf" "$_orm"
    STACK_COUNT=$((STACK_COUNT + 1))

  elif [ -f "package.json" ]; then
    _name="node"
    _pm=$([ -f "yarn.lock" ] && echo "yarn" || ([ -f "pnpm-lock.yaml" ] && echo "pnpm" || echo "npm"))
    _detail=$([ -f "tsconfig.json" ] && echo "typescript" || echo "javascript")
    # Try to detect test framework from scripts without jq
    _tf=$(grep -o '"test"[[:space:]]*:[[:space:]]*"[^"]*"' package.json 2>/dev/null | grep -o 'jest\|vitest\|mocha' | head -1)
    [ -z "$_tf" ] && _tf="jest"
    _orm=$(_detect_orm node)
    _export_stack "$STACK_COUNT" "$_name" "backend" "$_detail" "$_pm" "$_tf" "$_orm"
    STACK_COUNT=$((STACK_COUNT + 1))

  elif ls *.sln 2>/dev/null | head -1 | grep -q '.sln'; then
    _name="dotnet"
    SOLUTION_FILE=$(ls *.sln 2>/dev/null | head -1)
    _export_stack "$STACK_COUNT" "$_name" "backend" "" "dotnet" "xunit" "efcore"
    STACK_COUNT=$((STACK_COUNT + 1))

  elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
    _name="python"
    _pm=$([ -f "pyproject.toml" ] && echo "poetry" || echo "pip")
    _orm=$(_detect_orm python)
    _export_stack "$STACK_COUNT" "$_name" "backend" "" "$_pm" "pytest" "$_orm"
    STACK_COUNT=$((STACK_COUNT + 1))

  elif [ -f "go.mod" ]; then
    _name="go"
    _orm=$(_detect_orm go)
    _export_stack "$STACK_COUNT" "$_name" "backend" "" "go" "go test" "$_orm"
    STACK_COUNT=$((STACK_COUNT + 1))

  elif [ -f "pom.xml" ]; then
    _name="java"
    _orm=$(_detect_orm java)
    _export_stack "$STACK_COUNT" "$_name" "backend" "" "maven" "junit" "$_orm"
    STACK_COUNT=$((STACK_COUNT + 1))

  elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    _name="java"
    _orm=$(_detect_orm java)
    _export_stack "$STACK_COUNT" "$_name" "backend" "" "gradle" "junit" "$_orm"
    STACK_COUNT=$((STACK_COUNT + 1))

  elif [ -f "Gemfile" ]; then
    _name="ruby"
    _export_stack "$STACK_COUNT" "$_name" "backend" "" "gem" "rspec" "activerecord"
    STACK_COUNT=$((STACK_COUNT + 1))
  fi

  # --- Frontend detection (secondary stack for monoliths) ---
  if [ "$STACK_COUNT" -gt 0 ] && [ "$STACK_0_NAME" != "node" ]; then
    if [ -f "package.json" ]; then
      _pm=$([ -f "yarn.lock" ] && echo "yarn" || ([ -f "pnpm-lock.yaml" ] && echo "pnpm" || echo "npm"))
      _detail=$([ -f "tsconfig.json" ] && echo "typescript" || echo "javascript")
      _tf=$(grep -o '"test"[[:space:]]*:[[:space:]]*"[^"]*"' package.json 2>/dev/null | grep -o 'jest\|vitest\|mocha' | head -1)
      _export_stack "$STACK_COUNT" "node" "frontend" "$_detail" "$_pm" "$_tf" ""
      STACK_COUNT=$((STACK_COUNT + 1))
    elif ls public/js/*.js resources/js/*.js assets/js/*.js static/js/*.js 2>/dev/null | head -1 | grep -q '.js'; then
      _export_stack "$STACK_COUNT" "js-assets" "frontend" "javascript" "" "" ""
      STACK_COUNT=$((STACK_COUNT + 1))
    fi
  fi

  # --- Determine TYPE ---
  if [ "$STACK_COUNT" -eq 0 ]; then
    STACK_COUNT=1
    _export_stack 0 "unknown" "" "" "" "" ""
    TYPE="backend"
  elif [ "$STACK_COUNT" -gt 1 ]; then
    TYPE="monolith"
  else
    TYPE="backend"
  fi

  # Flat aliases from first stack
  STACK="$STACK_0_NAME"
  STACK_DETAIL="$STACK_0_DETAIL"
  PACKAGE_MANAGER="$STACK_0_PACKAGE_MANAGER"
  TEST_FRAMEWORK="$STACK_0_TEST_FRAMEWORK"
  ORM="$STACK_0_ORM"

  # Auto-detect DATABASE from any stack's ORM
  DATABASE="false"
  for i in $(seq 0 $((STACK_COUNT - 1))); do
    _orm_var="STACK_${i}_ORM"
    if [ -n "${!_orm_var}" ]; then
      DATABASE="true"
      break
    fi
  done

  DB_ENGINE=""
  BASE_BRANCH="dev"
  BRANCH_PREFIX=""
  TASK_TRACKER="none"
fi

# Export for use by calling scripts
export STACK STACK_DETAIL TYPE PACKAGE_MANAGER TEST_FRAMEWORK
export SOLUTION_FILE DATABASE DB_ENGINE ORM
export TASK_TRACKER BASE_BRANCH BRANCH_PREFIX
export STACK_COUNT
