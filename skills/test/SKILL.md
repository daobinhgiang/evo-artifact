---
name: test
description: >-
  Orchestrates end-to-end / UI feature testing by driving the LIVE app in real browsers via
  multiple parallel Playwright MCP servers, one tester subagent per flow, all running
  simultaneously. Use whenever the user wants to test, QA, smoke-test, verify, or check that a
  feature, page, or user flow actually works in the running app — triggered by "/test", "/test
  here", "/test all", "/test docs", "test this feature", "QA the changes", "does this flow
  work", or after building/changing UI that needs human-style verification. Maintains a
  TEST_MATRIX.md of documented flows. NOT for unit/integration tests in code (that's a normal
  test runner) and NOT for a single quick check you can eyeball — this is for multi-flow,
  browser-driven verification fanned across parallel agents.
version: 1.0.0
---

# /test — Parallel browser-driven feature testing

This skill QA-tests a running web app the way a human would: it opens **real browsers** through
several **isolated Playwright MCP servers at once**, hands **one flow to each subagent**, and runs
them **simultaneously** to save wall-clock time. It keeps the catalog of testable flows in
`TEST_MATRIX.md` so testing is repeatable and nothing silently goes uncovered.

The guiding bias: **be thorough and fast.** Before fanning out, think **extremely long and hard** to
enumerate *every* case, story, and state that can happen to the target (Phase 1.5) — coverage gaps
are the one failure this skill exists to prevent. Then decompose aggressively, fan out widely, and
prefer speed slightly over token cost. Always document before testing, and never run without a known target.

## Prerequisite — Playwright MCP servers (the user must have these; ask Claude to set them up)

This skill cannot run without **Playwright MCP servers**, and they are **not installed by default**.
Surface this early — don't get halfway into a run and discover there's no browser to drive.

- **If none are configured, the user needs to ask Claude to install them — and Claude does the install.**
  This isn't something the user has to wire up by hand: when they say something like *"install the
  Playwright MCP servers for /test"* (or you detect none in Phase 0), **you** add them per
  `references/mcp-setup.md`, or point them at the repo's `install.sh --playwright`. Then they restart
  Claude Code so the servers connect.
- **Parallelism comes entirely from running multiple servers.** One Playwright MCP server = one browser
  = one flow at a time, i.e. **no parallelism**. To test N flows simultaneously you must have **N
  separate servers** configured (`playwright`, `playwright2`, `playwright3`, … — **minimum 3, no upper
  limit**). If only one server exists, this skill is reduced to serial testing — so when you find fewer
  servers than the run needs, **offer to add more before fanning out** (and if there are still fewer
  servers than flows, run in waves sized to the server count).

See `references/mcp-setup.md` for detection, the exact `--isolated` server config, and why separate
servers (not tabs) are the only way to get true parallel sessions.

## Commands

Parse the invocation argument first:

- **`/test`** or **`/test here`** → test only what changed **in this session** (what was just built).
- **`/test all`** → test everything documented in `TEST_MATRIX.md` plus all detected changes across the codebase.
- **`/test docs`** / `/test doc` / `/test document …` → **documentation only**. Run the investigation + documentation phases, update `TEST_MATRIX.md`, then **stop and wait** for the user to confirm before any browser runs.

No argument behaves like `/test here`.

---

## Phase 0 — Prepare & investigate (always run this first)

Do this on **every** invocation, including `/test docs`, before anything else. If the
**deep-exploration** skill is available, use it for the codebase investigation; otherwise
investigate manually (Glob/Grep/Read, git diff).

1. **Figure out what's under test.**
   - `/test here`: read this session's history to see what was built/changed. If the session has no clear build context, read `TEST_MATRIX.md`. If that file doesn't exist, read `AGENTS.md` (and `CLAUDE.md`/`README.md`) to orient.
   - `/test all`: enumerate everything in `TEST_MATRIX.md` **and** scan for changes (below).
2. **Read the docs that matter.** Read `TEST_MATRIX.md` and `AGENTS.md`, then follow their references to any feature-specific docs relevant to the target (specs, ADRs, design notes). Don't skim — these define expected behavior and the flows you'll assert against.
3. **Scan the codebase for untested changes.** Look for recent changes (git status/diff if available, or recently-modified source) that touch user-facing behavior and are **not** documented in `TEST_MATRIX.md`. If you find some, **list them and ask the user** whether to include them in this run (they may be intentional out-of-scope work).
4. **Confirm the tooling is present** (see `references/mcp-setup.md`):
   - **Playwright MCP installed?** If memory says the user already has it, skip the check and proceed. Otherwise verify a `playwright*` MCP server exists; if none, suggest installing it and stop.
   - **Enough parallel servers?** This skill needs several isolated Playwright MCP servers, named `playwright`, `playwright2`, `playwright3`, … — **as many as the user wants, with a minimum of 3 and no upper limit.** Detect how many are *currently* configured (check both the project `.mcp.json` / project block of `~/.claude.json` and the global config); never assume a fixed number. If there are fewer than 3, or fewer than the number of flows you intend to run, **help the user add more isolated ones** — default to enough to cover the flows, and always at least 3. See `references/mcp-setup.md`. Newly added servers require a Claude Code restart to connect.
5. **Verify accounts + data state BEFORE fanning out — cheap up front, expensive mid-run.** A tester
   that discovers a missing login or an empty queue halfway through has already burned a whole browser
   session. Pre-flight it with a few quick API calls (not browsers):
   - **Accounts:** for each Role the in-scope flows will use, do a quick API login (e.g. `curl` the
     auth endpoint) to confirm the account exists and the password works. Missing/seed-needed users are
     a blocker to fix now (seed/create), not for an agent to hit live.
   - **Data preconditions:** for each in-scope flow, confirm its required data actually exists — query
     the API/DB for "is there a record at status X / a non-empty queue / a book in stage Y?" If a flow
     needs a record in a state nothing is currently in, that flow is blocked until you seed/promote one.
   - **Also sanity-check the endpoints the flows lean on** (hit the key API route with a real token):
     a route that 500s for everyone (often masked as a CORS error in the browser) blocks every flow that
     touches it — far cheaper to catch here than via N failed browser runs.
   - Record every gap in the matrix's **Known issues / data prerequisites** section and resolve or scope
     it out with the user before Phase 3, so no agent wastes a session on a known-dead flow.

---

## Phase 1 — Document the flows (gate before any test)

A flow may only be tested once it's written down. This keeps runs reproducible and reviewable.

1. **If `TEST_MATRIX.md` doesn't exist**, offer to create one from `assets/TEST_MATRIX.template.md` and explain what it's for.
2. **If the requested feature's flows aren't documented**, interview the user to capture them. Ask **as many questions as needed, up to 7**, to nail down: the entry point/URL, the login role(s) and credentials, the exact step sequence, the expected outcome / pass criteria, edge cases, and how to tell success from failure. Then write the flows into `TEST_MATRIX.md` (format in `references/test-matrix-format.md`).
3. **If the docs are missing pieces** you uncovered in Phase 0 (undocumented changes the user agreed to test, or gaps in an existing entry), document those too, and **ask the user to confirm** the documented set before proceeding.
4. **`/test docs` stops here** — present what you documented and wait. Do not launch browsers.

---

## Phase 1.5 — Enumerate ALL the cases (mandatory thinking gate)

**Do not skip this and do not rush it.** This is where coverage is won or lost. Open
`references/case-enumeration.md` and follow its process in full: think **extremely long and hard**,
walk **every** dimension, and produce an exhaustive case list — then attack your own list with
"what else can happen?" until two consecutive passes add nothing new.

- A "case" is a distinct **story** (a path/state through the feature), not a UI click: `who ·
  precondition/state · action · expected outcome`. Cover happy paths *and* their variations, every
  role (allowed and blocked), every input/validation case, every entity status, empty/one/many/over-
  limit, error & failure paths (4xx/5xx/network), concurrency, persistence-after-refresh, navigation,
  cross-module ripples, responsive/a11y, and localization — per the reference's dimensions.
- **Record the case list in `TEST_MATRIX.md`** alongside the flows so coverage is visible and
  reproducible. Tag each case P0/P1/P2; nothing gets dropped from the list — priority only governs
  run order when the parallel budget is tight.
- For `/test here`, enumerate exhaustively for the **changed** surface; for `/test all`, for every
  documented feature in scope. If a case's expected outcome is genuinely unknown, surface it as an
  open question for the user rather than silently omitting it.
- **`/test docs` includes this enumeration** in what it documents, then still stops before browsers.

This list is the input to Phase 3's decomposition — you cannot decompose into flows what you haven't
first enumerated as cases.

---

## Phase 2 — Pick the subagent model (hard gate)

The tester subagents run on a **cheaper/faster model** — never the orchestrator's model, to control cost.

- Check `TEST_MATRIX.md` (its config/front-matter section) for a user-defined `subagent_model`.
- **If none is defined, STOP and ask the user which model to use.** Do not guess a default. Once they answer, record it in `TEST_MATRIX.md` so future runs don't re-ask.

**Right-size the model per flow — this is the default, not an afterthought.** A flow's model should
match its difficulty, not a single blanket choice. Pick per flow:

- **`claude-haiku`** for simple flows — gating checks, navigation, smoke tests, read-only assertions,
  "does this page render" — where there's no branching or judgment. These dominate most matrices.
- **`claude-sonnet`** for flows with branching, forms, multi-step state, or judgment (security/RBAC
  probing, conflict resolution, anything where the agent must reason about what it sees).

Why this matters: defaulting *everything* to the stronger model silently doubles cost on the many
flows that didn't need it. If `subagent_model` is set to a single value, honor it; if it's `mixed`,
choose per flow using the split above (tag each flow's tier when you decompose in Phase 3).

---

## Phase 3 — Orchestrate the parallel run

This is the core. Read `references/subagent-prompt.md` for the exact subagent briefing template.

1. **Decompose the Phase-1.5 case list into flows.** Group the enumerated cases into independent,
   self-contained flows/user-stories — **every P0 and P1 case must land in some flow**; don't quietly
   leave cases untested. **Be aggressive — never fewer than 3 subagents; 4–5+ is the sweet spot, and an
   honestly-enumerated feature usually needs more.** Split by role, by path, by happy/edge/error case —
   favor more, narrower agents over a few broad ones. We optimize for speed and coverage over frugality.
   If a wave can't cover every case at once, run additional waves rather than dropping cases.
   As you decompose, **tag each flow with its model tier** (Phase 2) and **give it a step budget** —
   a cap on how much the tester should explore (e.g. "step through ≤6 representative items, one per
   distinct type/state — not all of them" and "≤2 attempts per control, stop once the outcome is
   confirmed or clearly fails"). Open-ended flows balloon: in past runs a single agent spent 140+ tool
   calls grinding one control, or stepped 14 near-identical items when 6 covered the matrix. A narrow
   flow with a budget is cheaper and sharper than a broad one without.
2. **Assign one isolated MCP server per flow.** Map flow 1 → `playwright`, flow 2 → `playwright2`,
   flow 3 → `playwright3`, … Each subagent must use **only its assigned namespace** (e.g.
   `mcp__playwright3__*`) — sharing one browser across agents makes them collide. Use as many servers
   as are configured (**minimum 3, no maximum**); if there are more flows than servers, run in
   **waves sized to the number of servers**.
3. **Dispatch them simultaneously.** Launch all subagents for a wave **in a single message** (multiple
   Agent tool calls at once) so they truly run in parallel. Use `subagent_type: general-purpose`
   (NOT the built-in `tester` agent — it's hard-wired to `mcp__playwright__*` only and can't see the
   other servers). Set each Agent call's `model` to **that flow's chosen tier** (Phase 2) — don't
   blanket every agent with the strongest model; haiku flows and sonnet flows can launch in the same wave.
4. **Each subagent** (per the template): loads its server's deferred tools via ToolSearch, logs in
   with the documented role, performs its flow step-by-step taking snapshots/screenshots, watches
   the browser console + network for errors, and returns a **structured verdict** (steps done,
   per-step observations, console/HTTP errors, PASS/FAIL with justification). Tell them to leave the
   browser open so you can spot-check, then you close it in Phase 5.

**Default to full MCP runs.** Only fall back to a pre-written script (Phase 5) when it's *truly*
obvious the flow is mechanical and high-volume — be strict; the live MCP run is the default because
it catches rendering, console, and UX problems a script glosses over.

---

## Phase 4 — Report

Aggregate the subagents' results into one report for human QA:

- **Per-flow verdict** (✅ pass / ⚠️ partial / 🚫 blocked) with the key evidence and any console/HTTP errors.
- **Cross-cutting findings** — bugs, blockers, or data-state issues that affect multiple flows. When a browser reports a CORS/`ERR_FAILED` on an API call, suspect a backend 5xx that stripped CORS headers — verify the real status (e.g. `curl` the endpoint) before calling it a CORS-config problem.
- **Coverage gaps** — cross-reference results against the **Phase-1.5 case list**: every enumerated
  case should be run, deferred (with reason), or flagged inconclusive. Report cases run vs. enumerated
  (and which P-tier was deferred). Never present partial coverage as complete.

---

## Phase 5 — Repeatability & cleanup (after every run)

1. **Only suggest a repeatable script when it's genuinely justified — default to NOT suggesting.**
   Most flows should just stay on live MCP; floating a "want a script?" idea after every run is noise
   that trains the user to ignore you. Stay **silent** unless *all* of these clearly hold:
   - the flow is **mechanical and fully deterministic** — no human-like judgment or visual assessment that an agent is needed for;
   - its **UI is stable**, not under active development (a script written against churning UI just rots); and
   - it will **genuinely be re-run often** as a regression check — the user runs it repeatedly, or has explicitly asked for regression coverage.

   A one-off verification, an exploratory flow, or anything tied to changing UI is **not** a
   candidate — say nothing. When the bar truly is met, make the offer **once**, briefly, with the
   concrete payoff (a regression flow re-run many times saves ~40–80k tokens each run); on the user's
   OK, write the script and record it under "Repeatable scripts" in `TEST_MATRIX.md`. When in doubt,
   don't suggest.
2. **Clean up at the end of the session — proactively suggest it, don't let debris pile up.** A `/test`
   run leaves two kinds of mess behind, and both should be cleared once the Phase-4 report is delivered:
   - **Open browser sessions.** Every tester was told to leave its browser open (Phase 3) so you could
     spot-check. Now close them — **all of them, not just the first.** Call `mcp__<server>__browser_close`
     for *each* server namespace the run used (`playwright`, `playwright2`, `playwright3`, …), then sweep
     any stray browser processes the wave spawned. Leaving half a dozen headful browsers running after the
     run leaks memory and slows the next run.
   - **Screenshot dumps.** The `.playwright-mcp/` directory fills up fast — a single multi-flow run can add
     100+ images. **Tell the user what accumulated** (e.g. "`.playwright-mcp/` has N screenshots from this
     run") and **suggest deleting them** (`rm -rf .playwright-mcp/` plus any ad-hoc screenshot/scratch
     dirs) rather than removing them silently — the user may want to review the evidence first. Delete on
     their go-ahead.
   - **If it's already clean** (no sessions left open, no screenshot dump), say so in one line and skip —
     don't nag.

   Keep caches that are genuinely useful for future runs. If the repo has accumulated a lot of *stale*
   test/build cache beyond this run, point that out and suggest clearing it too.

---

## Reference files
- `references/case-enumeration.md` — **(Phase 1.5)** the exhaustive case/story taxonomy and the think-long-and-hard enumeration process. Read it every run.
- `references/mcp-setup.md` — detect, install, and configure the parallel Playwright MCP servers (isolated).
- `references/subagent-prompt.md` — the per-flow tester subagent briefing template.
- `references/test-matrix-format.md` — structure of `TEST_MATRIX.md` and the config keys this skill reads.
- `assets/TEST_MATRIX.template.md` — starter file to copy when a project has none.
