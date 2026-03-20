# ClickUp Skill — Setup Instructions

## Requirements

- Node.js 18+

## Installation

1. The `clickup/` folder is already included in this plugin at `skills/clickup/`.

2. Install dependencies:

```bash
cd .claude/dev-workflow/skills/clickup
npm install
```

3. Configure your API token:

```bash
cp .claude/dev-workflow/skills/clickup/.env.example .claude/dev-workflow/skills/clickup/.env
# Edit .env and set your CLICKUP_API_TOKEN (starts with pk_)
# Generate at: ClickUp Settings > Apps > API Token
```

4. (Optional) Set a default list so you can create tasks without specifying a list ID every time:

```bash
# In .claude/dev-workflow/skills/clickup/.env
CLICKUP_DEFAULT_LIST_ID=your_list_id_here
```

## .gitignore

Add this entry to your `.gitignore`:

```
.claude/dev-workflow/skills/clickup/.env
```

## Verify

```bash
node .claude/dev-workflow/skills/clickup/query.mjs me
```

Should print your ClickUp user info.

## Usage

See `SKILL.md` for the full command reference.
