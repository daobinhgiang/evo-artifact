# Evovi Skills

[Claude Code](https://claude.com/claude-code) skills for Evovi engineers.

> **Internal use only.** These skills encode Evovi's engineering conventions and are intended
> for use by Evovi staff on Evovi projects. Not for external distribution.

## Skills

| Skill | Purpose |
|---|---|
| [`senior-engineer`](skills/senior-engineer/SKILL.md) | Senior-engineer persona + router. Weighs scalability on every backend/DB/schema decision and routes work to the right specialist skill. |
| [`ship`](skills/ship/SKILL.md) | One-command pipeline: branch → commit → push → PR, with optional merge + deploy. Defaults to Evovi's `develop`-branch flow and never touches `main`. |

## Quick start

```bash
git clone https://github.com/daobinhgiang/evo-artifact.git && cd evo-artifact
./scripts/install.sh             # global  -> ~/.claude/skills
./scripts/install.sh --project   # project -> ./.claude/skills
```

Restart Claude Code, run `/help`, and confirm both skills appear. Maintaining the skills?
See [CONTRIBUTING.md](CONTRIBUTING.md).

## Documentation

**→ [Full usage guide](docs/USAGE.md)** — install options, triggers, all `/ship` modes, and troubleshooting.

For Evovi repos, drop [`templates/AGENTS.evovi.md`](templates/AGENTS.evovi.md) into your
project as `AGENTS.md` so `/ship` follows the `develop` + dokploy deploy flow automatically.

## Layout

```
skills/
  senior-engineer/SKILL.md   # persona + router
  ship/SKILL.md              # shipping pipeline
docs/USAGE.md                # how to use the skills
templates/AGENTS.evovi.md    # drop-in AGENTS.md for Evovi repos
```
