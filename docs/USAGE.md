# Using the Evovi Skills

Install and use the two [Claude Code](https://claude.com/claude-code) skills in this repo:
**`senior-engineer`** and **`ship`**. Internal Evovi use only — see the [README](../README.md).

| Skill | What it does |
|---|---|
| **`senior-engineer`** | Senior-engineer persona + router. Shapes how Claude reasons about engineering, weighs scalability on every backend/DB/schema decision, and routes to specialist skills (code review, audit, app-wide refactor, deep exploration, plan→build). |
| **`ship`** | One-command pipeline: branch → commit → push → PR, with optional merge + deploy. Reads each repo's `AGENTS.md`, cuts a new branch off `develop`/`staging`, never touches `main`. |

## Install

Global (per engineer):

```bash
git clone https://github.com/daobinhgiang/evo-artifact.git && cd evo-artifact
mkdir -p ~/.claude/skills && cp -R skills/senior-engineer skills/ship ~/.claude/skills/
```

Per-project (shared repo) — copy into `.claude/skills/` and commit:

```bash
mkdir -p .claude/skills && cp -R /path/to/evo-artifact/skills/* .claude/skills/
```

Verify: restart Claude Code, run `/help`, and confirm both skills are listed.

## `senior-engineer`

Ambient — once installed it shapes engineering work; you rarely call it by name. Triggers on:
engineering opinions ("act as a senior engineer"), planning a feature/change, and any
backend/DB/schema question (it answers in tiers by scale and recommends the right one).

It explores the codebase before answering, pushes back on designs that won't scale, accepts
your override, and ends with concrete next steps. It routes substantive work to specialist
skills:

| You want… | Routes to |
|---|---|
| Review a specific diff/PR/file | `code-quality-review` |
| Audit the whole codebase | `codebase-review` |
| Change something across the app | `codebase-wide-change` |
| Build an approved plan | `parallel-execution` |
| Understand code before acting | `deep-exploration` |
| Triage Codex PR comments | `codex-triage` |

> Routed-to skills are **separate** and not bundled here. `senior-engineer` works alone as a
> persona; install the others to use routing fully.

## `ship`

Run `/ship`. Default is autonomous: reads `AGENTS.md`, cuts a new branch off the secondary
branch (`develop`/`staging`), commits all changes, pushes, and opens a PR. Never touches
`main`/`master`. Pauses only for a suspected secret, rejected push, or blocking conflict.

| Command | Behavior |
|---|---|
| `/ship` | branch → commit → push → PR |
| `/ship no pr` | stop after push, no PR |
| `/ship this chat` / `here` | ship only this session's files |
| `/ship to <branch>` | target a specific PR base |
| `/ship from here` | ship current branch as-is |
| `/ship merge` | merge the PR + run production deploy |
| `/ship review` | review the diff after shipping |
| `/ship "message"` | use your commit summary |

Modes combine (`/ship here no pr`). `/ship` adapts to any convention you state and offers to
save it to `AGENTS.md`. For Evovi repos, drop in
[`templates/AGENTS.evovi.md`](../templates/AGENTS.evovi.md) so it knows the `develop` +
dokploy flow from the first run.

## Update & troubleshoot

- **Update:** `git pull`, then re-copy the `skills/*` folders.
- **Not in `/help`:** check the path is `~/.claude/skills/<name>/SKILL.md` and restart.
- **`/ship` can't open a PR:** run `gh auth login`.
- **Wrong PR base:** add an `AGENTS.md` shipping section or use `/ship to <branch>`.
