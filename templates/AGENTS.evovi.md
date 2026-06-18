# AGENTS.md

Drop this into an Evovi project repo as `AGENTS.md` so `/ship` follows Evovi conventions from
the first run. Edit the placeholders to match the specific project.

## Shipping

- **Primary branch:** `main` — protected, never committed/pushed/PR-targeted directly.
- **Secondary branch:** `develop` — the integration target. All work arrives via PRs from
  short-lived branches.
- **Branch naming:** `feat/<slug>`, `fix/<slug>`, or `ship/<slug>`.
- **PR base:** `develop`.
- **Merge strategy:** squash.

## Production Deploy

Merging to `develop` deploys to the dokploy environment (`dokploy.test.evovi.vn`).

### Migrations
```bash
# <project migration command, e.g. npm run migrate>
```

### Verify
```bash
# <health-check command or URL>
```
