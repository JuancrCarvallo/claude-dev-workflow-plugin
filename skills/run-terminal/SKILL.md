---
name: run-terminal
description: Terminal and CLI conventions for this project. Loaded automatically when running build, test, or install commands.
user-invocable: false
---

# Terminal Conventions

!`${CLAUDE_SKILL_DIR}/../../scripts/terminal-conventions.sh`

## General Rules (all stacks)
- Never use absolute paths in commands — working directory is always the project root
- Never run destructive commands (drop DB, delete files, force push) without explicit human confirmation
- If a command fails, read the error before retrying — do not loop blindly
- Check for a `Makefile` or project scripts before assuming default command names
- On build failure: retry once, then escalate to human
