# Screenshot capture — mechanism ladder & rules

The doc needs **files on disk**, not images you merely saw. Some browser tools
show you screenshots inline without persisting them anywhere you can write to —
that is *seeing*, not *capturing*. Probe before planning: run one end-to-end test
(capture → file exists → correct size) with a mechanism before committing the
whole shot list to it.

## The ladder (try in order, use the first that fully works)

### 1. Playwright MCP (or similar browser-automation MCP)
Best option: real files, controllable viewport, scriptable logins, parallel
instances. Detect via tool discovery (`browser_navigate`, `browser_snapshot`,
`browser_take_screenshot`, tools prefixed `mcp__playwright*`). Multiple server
instances (`playwright`, `playwright2`, …) = one lane per instance for parallel
capture. Confirm where the PNG lands (usually a `.playwright-mcp/` or configured
output dir) and move it to the doc's `images/` under the plan's filename.

### 2. Sandbox headless browser (when the sandbox can reach the app)
If the session has a shell sandbox with network access to the app's domain
(verify: `curl -s -o /dev/null -w '%{http_code}' https://<app>/` → 200/30x, not
000/403), install and drive headless Chromium (playwright or puppeteer via npm)
yourself. Full control: set viewport exactly, script the login once, loop the
shot list, write PNGs straight into the repo. If curl shows a proxy error like
`blocked-by-allowlist`, the domain isn't allowlisted — tell the user which
domains to allow (app + API + asset/CDN hosts, discoverable from the page's
resource hosts) and note that allowlist changes usually need a **fresh session**
to take effect.

### 3. In-app browser extension (e.g. Claude-in-Chrome)
Can drive the real browser and *see* screenshots. Only usable for files if the
session persists screenshots to disk (a `save_to_disk`-style option that
actually reports a path you can read). Test one capture first. If it can't
persist: do NOT try to smuggle pixels out via canvas/base64/clipboard —
data-export guards block this by design; respect them.

### 4. Nothing works → delegate to the user
Produce a precise manual shot list (filename · account · exact app state · what
must be visible · viewport/theme), have the user capture into a folder, then
verify each image against the plan and continue with phase 4.

## Consistency rules (apply to every mechanism)

- **One viewport for the whole doc set.** Match existing images if updating
  (check with `file`/PNG header — e.g. 1440×900); otherwise pick 1440×900,
  deviceScaleFactor 1.
- **One theme.** If the app has light/dark, force the same theme everywhere
  (docs usually read best in light). Toggle it after login; many apps persist
  theme per account/browser — verify on each fresh login.
- **The right account per audience.** UIs render differently per role (different
  panels, different button labels). Reviewer-doc shots must come from a
  reviewer-role account, manager-doc shots from a manager account. Never
  substitute.
- **Arrange the state the plan demands**: correct tab active, dialog open,
  hover state if a control only appears on hover, list non-empty if the doc
  describes rows (empty states get their own shot only if documented).
- **PNG, exact planned filename, into the doc's `images/` dir.** Stable names
  let future recaptures replace files without editing the markdown.
- **Demo data note**: capture from a demo/test environment when available and
  say so in the doc's intro; avoid real user PII in shots.

## Side-effect hygiene

Arranging states can mutate data: claiming a work item, joining a pool, opening
a form. Rules:
- Prefer read-only states; when a mutation is unavoidable (e.g. a grading screen
  requires claiming an item), do it, capture, then **undo it** (return the claim,
  leave the pool, cancel the dialog) before finishing the lane.
- Never submit verdicts/forms just to screenshot the result — capture the dialog
  pre-submit, then cancel.
- Log every mutation in the lane report so the orchestrator can double-check the
  cleanup happened.

## Finding URL & credentials

Look for: seed scripts (`seed*.py`, fixtures) with emails/passwords, env files
and CI configs with deployment hostnames, repo docs (AGENTS/README) naming
test/staging environments. Prefer the environment the audience actually uses;
if only a test env is reachable, confirm with the user that it reflects the
production UI. Never use production accounts with real data without explicit
user direction.
