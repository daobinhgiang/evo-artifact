---
name: product-onboarding-docs
description: Generate or update role-based onboarding / how-to documentation for any web product, with verified screenshots of the live app. Use this skill whenever the user asks to write, refine, review, or update onboarding docs, user guides, usage instructions, training material for a specific role (reviewer, manager, operator, admin…), or to bring existing docs/screenshots back in sync after the app UI changed — even if they only say something like "update the docs to match the app" or "write a guide for the QA team". Works regardless of which screenshot mechanism is available (Playwright MCP, an in-app browser extension, or a sandbox headless browser).
version: 1.0.0
---

# Product Onboarding Docs

Produce documentation that a **specific role** (a reviewer, a manager, an operator…)
can read once and then do their job in the product. The doc is grounded in three
sources that must all agree: the **live app**, the **codebase**, and any
**existing docs** — and when they disagree, what the audience actually sees in the
app wins.

## Why this skill is strict about verification

Onboarding docs rot silently. UIs get renamed, menu items disappear for a role,
features get gated behind flags — and a doc that says "click *Assign QA*" when that
button no longer exists for the reader destroys trust in the whole document. So the
core rule: **never write a UI claim you have not seen with your own eyes in the
running app**, and never trust an existing doc's claim without re-verifying it.
Existing docs are a *starting outline*, not a source of truth.

## Non-negotiables (learned the hard way)

1. **Exact labels, never paraphrased or translated.** Users find things by matching
   text on screen. If the menu item is "Việc của tôi" but the page it opens is
   titled "Việc QA của tôi", the doc uses each string exactly where it applies
   ("menu **Việc của tôi** — opens the **'Việc QA của tôi'** page"). Never
   translate a label into the doc's prose language; quote it verbatim.
2. **Role visibility is defined by the UI, not the API.** A feature the role cannot
   see in the app must not be mentioned **at all** — not as "you don't have access
   to X", simply absent. An unblocked API route or a reachable deep URL does not
   count as visible. Verify visibility by logging in *as that role* and looking:
   nav gating, route guards, per-item `visibleInViews`-style flags, feature flags.
3. **Never name internal modes/flags.** If the product runs in some configuration
   mode (a feature flag, a customer-specific mode), document what the app *shows*
   in that mode without ever mentioning the mode's name.
4. **Live app beats code; ask when they disagree.** The deployed app the audience
   uses may be older or newer than the repo. If code and deployed UI conflict
   (different labels, missing menu items), surface the diff to the user and ask
   which is authoritative before writing — don't silently pick one.
5. **Just-enough context.** Give the role the surrounding workflow context needed
   to do the job (e.g. "after you approve, the question moves to publisher
   review") but nothing about org structure, other roles' tooling, or pipeline
   internals they never touch.
6. **Leave no side effects.** Capturing screenshots often requires acting in the
   app (claiming a task, opening a dialog). Undo everything afterwards — return
   claims, cancel dialogs, don't submit forms. Track every mutation you make.

## The four phases

Run these in order. Phases 1–3 gather; phase 4 writes.

### Phase 1 — Deep Explore

Goal: a complete, role-scoped map of the product, plus any existing docs.

- If a `deep-exploration` skill is available, invoke it with the product +
  role as the target. If not, follow `references/deep-explore-fallback.md`
  (same divide-and-conquer method, baked in).
- Fan out read-only subagents (3 minimum, more is better). Always dedicate:
  - **one subagent to hunting existing onboarding docs** — search the repo for
    doc folders (`docs/`, `onboarding/`, `guides/`, `README`s), files whose names
    mention the role/guide/manual (in any language), and image folders that look
    like doc screenshots. Report format, structure, and every UI claim they make
    (these become the verification checklist, not facts).
  - one or more subagents on **role access**: route guards, nav/menu definitions,
    permission constants, feature flags — produce the definitive list of what this
    role can see, page by page, and what it must never hear about.
  - subagents on the **workflow itself**: the end-to-end user stories this role
    performs, states, transitions, dialogs, validation rules, keyboard shortcuts.
  - one subagent on **project context**: what product this is, what the
    neighboring systems/steps are, enough to explain *why* the role's work matters.
- Then verify the map **against the live app**: log in as a real account of that
  role (get URL + credentials from the user, seed files, or env configs — ask if
  not findable) and walk every page the map claims the role can see. Note every
  label, button, tab, empty-state, and any mismatch with code or existing docs.

### Phase 2 — Blueprint (plan the doc and the shot list)

Synthesize the exploration into two artifacts **before** writing anything:

1. **A section outline** following `references/doc-template.md` (quick-start box,
   TOC table, numbered §sections, criteria tables, shortcuts section). Decide what
   information goes in which section and which claims still need verification.
2. **A screenshot shot list** — one entry per image with: exact filename
   (stable, kebab-case, role-prefixed, e.g. `reviewer-grading.png`), the app
   state to arrange (account, page, tab, dialog open?), and what must be visible.
   Coverage rules:
   - at least one screenshot per page the doc discusses;
   - at least one per user step — and every control the step tells the user to
     click must be visible in that step's screenshot. The moment a step involves
     a control not visible in the previous shot (a dialog opened, a tab changed,
     scrolled out of view), that step gets its own shot;
   - reuse one screenshot across steps only while all referenced controls remain
     visible in it.
3. Group the shot list into **independent parallel lanes** (per account/page area)
   for delegation, and write a short **context pack** for the capture agents:
   app URL, credentials per role, viewport, theme, capture mechanism (from
   `references/screenshot-capture.md`), file naming, output directory, and the
   cleanup rules for any state they create. Builders read this one pack instead
   of re-deriving everything.

### Phase 3 — Gather (parallel screenshot capture)

- First, **probe capture mechanisms once** and pick the best available — the
  ladder and per-mechanism instructions are in
  `references/screenshot-capture.md`. Do this before spawning agents so every
  lane uses the same working mechanism and consistent settings.
- Spawn as many parallel subagents as there are independent lanes. Each agent:
  logs in as its assigned role, arranges each state, captures at the standard
  viewport/theme, saves under the exact filename into the images directory, and
  undoes any state it created (return claims, close dialogs).
- Lanes that share an account but touch different pages can still parallelize;
  lanes that mutate shared state (e.g. both claim from the same queue) must be
  serialized or given separate accounts.
- Verify afterwards: every filename from the shot list exists, correct
  dimensions, and spot-open a few to confirm they show what the plan demanded
  (right tab, dialog open, light/dark theme consistent).

### Phase 4 — Compose (write the doc)

- Write (or update) the markdown following `references/doc-template.md`,
  placing each screenshot immediately after the paragraph that describes the
  UI it shows, with descriptive alt text and an italic caption naming the exact
  screen/dialog.
- When **updating** existing docs: keep their structure and voice; change only
  what the app contradicts, plus whatever the user explicitly asked to improve.
  Every claim you keep is a claim you verified. Remove sections about features
  the role can no longer see; add sections for new visible features.
- Match the language conventions of the repo/team (e.g. prose in the team's
  language, technical identifiers and verbatim UI strings untouched).
- If the repo has a build step for a distributable format (docx/pdf), run it and
  validate the output. If the user wants a docx and no build exists, use the
  docx skill/tooling available in the session.
- Final self-review pass: re-open the live app one more time and spot-check the
  five most operationally critical claims (main button labels, menu paths, the
  primary workflow) against the finished doc before presenting it.

## Delegation notes

- Exploration subagents are read-only; capture subagents may act in the app but
  must log every mutation and undo it.
- Give each subagent the context pack + only its own lane; don't make agents
  re-read the whole codebase.
- If no subagent mechanism exists in the session, run the phases yourself in the
  same order; parallelism is an optimization, not a requirement.

## Deliverables

- `docs` markdown file(s), one per role/audience.
- An `images/` directory with all referenced screenshots under stable names
  (stable names mean future recaptures replace files without touching the text).
- Distributable format (docx/pdf) if the repo builds one or the user asks.
- A short report: what changed vs. existing docs, any code-vs-app mismatches
  found (with your recommendation), and any claims you could not verify.
