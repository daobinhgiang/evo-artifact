# Contributing

For Evovi engineers maintaining these skills.

## Workflow

- Branch off `develop`; PR back into `develop`. Never commit to `main`.
- Run `./scripts/install.sh` to test changes locally before pushing.
- CI (`validate-skills`) checks every `skills/*/SKILL.md` has `name`, `description`, `version`.

## Editing a skill

- Edit `skills/<name>/SKILL.md`. Keep the YAML frontmatter intact.
- **Bump `version:`** on any behavior change (semver).
- Update `evals/evals.json` when you change triggering or behavior.
- Keep the `description:` accurate — it's what decides when the skill fires.

## Docs

Keep `README.md` and `docs/USAGE.md` in sync with skill behavior. Docs stay concise.
