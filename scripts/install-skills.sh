#!/usr/bin/env bash
# install-skills.sh — Install dev-workflow skills to .claude/skills/ in Claude Code format.
#
# Run from the project root:
#   bash .claude/dev-workflow/scripts/install-skills.sh
#
# What it does:
#   1. Reads each skills/<name>/SKILL.md from the dev-workflow plugin
#   2. Resolves !`command` lines by running the referenced scripts
#   3. Writes .claude/skills/<name>/SKILL.md with the output embedded as flat text
#   4. Cleans up old flat-file skills (.claude/skills/<name>.md) from previous installs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$(cd "$SCRIPT_DIR/../skills" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SKILLS_DEST="$PROJECT_ROOT/.claude/skills"

mkdir -p "$SKILLS_DEST"

echo "Installing dev-workflow skills to $SKILLS_DEST"
echo ""

installed=()

for skill_dir in "$SKILLS_SRC"/*/; do
    [[ -d "$skill_dir" ]] || continue

    name="$(basename "$skill_dir")"
    src="$skill_dir/SKILL.md"
    dest_dir="$SKILLS_DEST/$name"
    dest="$dest_dir/SKILL.md"

    [[ -f "$src" ]] || continue

    # Create skill directory (Claude Code standard format)
    mkdir -p "$dest_dir"

    # Process SKILL.md: resolve !`command` lines into flat text output
    output=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^!\`(.+)\`$ ]]; then
            cmd="${BASH_REMATCH[1]}"
            # Substitute ${CLAUDE_SKILL_DIR} with the actual skill source directory
            cmd="${cmd//\$\{CLAUDE_SKILL_DIR\}/$skill_dir}"
            cmd="${cmd//\$CLAUDE_SKILL_DIR/$skill_dir}"
            # Run from project root so detect-stack.sh can find .claude/dev-workflow.json
            injected="$(cd "$PROJECT_ROOT" && bash "$cmd" 2>&1 || echo "<!-- script failed: $cmd -->")"
            output+="$injected"$'\n'
        else
            output+="$line"$'\n'
        fi
    done < "$src"

    printf '%s' "$output" > "$dest"

    # Clean up old flat-file format from previous installs
    old_flat="$SKILLS_DEST/$name.md"
    if [ -f "$old_flat" ]; then
        rm -f "$old_flat"
        echo "  - removed old flat file: $name.md"
    fi

    installed+=("$name")
    echo "  + $name/SKILL.md"
done

echo ""
echo "Installed ${#installed[@]} skill(s): ${installed[*]}"
echo ""
echo "Done. Re-run this script whenever you update the dev-workflow plugin or reconfigure the stack."
