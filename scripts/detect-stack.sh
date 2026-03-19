#!/bin/bash
# Reads .claude/dev-workflow.json if present.
# Falls back to auto-detection from project files.
# Outputs a shell-sourceable set of variables.

CONFIG=".claude/dev-workflow.json"

if [ -f "$CONFIG" ]; then
  STACK=$(jq -r '.stack // empty' "$CONFIG")
  TYPE=$(jq -r '.type // empty' "$CONFIG")
  STACK_DETAIL=$(jq -r '.stack_detail // empty' "$CONFIG")
  PACKAGE_MANAGER=$(jq -r '.package_manager // empty' "$CONFIG")
  TEST_FRAMEWORK=$(jq -r '.test_framework // empty' "$CONFIG")
  SOLUTION_FILE=$(jq -r '.solution_file // empty' "$CONFIG")
  DATABASE=$(jq -r '.database // empty' "$CONFIG")
  DB_ENGINE=$(jq -r '.db_engine // empty' "$CONFIG")
  ORM=$(jq -r '.orm // empty' "$CONFIG")
  TASK_TRACKER=$(jq -r '.task_tracker // empty' "$CONFIG")
  BASE_BRANCH=$(jq -r '.base_branch // "dev"' "$CONFIG")
  BRANCH_PREFIX=$(jq -r '.branch_prefix // ""' "$CONFIG")
else
  # Auto-detect from project files
  if [ -f "package.json" ]; then
    STACK="node"
    PACKAGE_MANAGER=$([ -f "yarn.lock" ] && echo "yarn" || ([ -f "pnpm-lock.yaml" ] && echo "pnpm" || echo "npm"))
    STACK_DETAIL=$([ -f "tsconfig.json" ] && echo "typescript" || echo "javascript")
    TEST_FRAMEWORK=$(jq -r '.scripts.test // empty' package.json 2>/dev/null | grep -o 'jest\|vitest\|mocha' | head -1)
    [ -z "$TEST_FRAMEWORK" ] && TEST_FRAMEWORK="jest"
  elif ls *.sln 2>/dev/null | head -1 | grep -q '.sln'; then
    STACK="dotnet"
    SOLUTION_FILE=$(ls *.sln 2>/dev/null | head -1)
    TEST_FRAMEWORK="xunit"
    PACKAGE_MANAGER="dotnet"
  elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
    STACK="python"
    PACKAGE_MANAGER=$([ -f "pyproject.toml" ] && echo "poetry" || echo "pip")
    TEST_FRAMEWORK="pytest"
  elif [ -f "go.mod" ]; then
    STACK="go"
    TEST_FRAMEWORK="go test"
    PACKAGE_MANAGER="go"
  elif [ -f "pom.xml" ]; then
    STACK="java"
    PACKAGE_MANAGER="maven"
    TEST_FRAMEWORK="junit"
  elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    STACK="java"
    PACKAGE_MANAGER="gradle"
    TEST_FRAMEWORK="junit"
  elif [ -f "Gemfile" ]; then
    STACK="ruby"
    PACKAGE_MANAGER="gem"
    TEST_FRAMEWORK="rspec"
  else
    STACK="unknown"
  fi

  # Auto-detect DB/ORM
  if [ "$STACK" = "node" ] && [ -f "prisma/schema.prisma" ]; then
    DATABASE="true"; ORM="prisma"
  elif [ "$STACK" = "node" ] && grep -q '"typeorm"' package.json 2>/dev/null; then
    DATABASE="true"; ORM="typeorm"
  elif [ "$STACK" = "python" ] && grep -q 'sqlalchemy' requirements.txt 2>/dev/null; then
    DATABASE="true"; ORM="sqlalchemy"
  elif [ "$STACK" = "dotnet" ]; then
    DATABASE="true"; ORM="efcore"
  elif [ "$STACK" = "go" ] && [ -f "go.mod" ] && grep -q 'gorm' go.mod 2>/dev/null; then
    DATABASE="true"; ORM="gorm"
  elif [ "$STACK" = "ruby" ]; then
    DATABASE="true"; ORM="activerecord"
  else
    DATABASE="false"; ORM=""
  fi

  BASE_BRANCH="dev"
  BRANCH_PREFIX=""
  TASK_TRACKER="none"
  TYPE="backend"
fi

# Export for use by calling scripts
export STACK STACK_DETAIL TYPE PACKAGE_MANAGER TEST_FRAMEWORK
export SOLUTION_FILE DATABASE DB_ENGINE ORM
export TASK_TRACKER BASE_BRANCH BRANCH_PREFIX
