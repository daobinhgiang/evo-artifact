---
name: parallel-execution
description: "Execute an approved plan by fanning work across parallel builder subagents, with tester agents verifying each part as its builder finishes and bouncing failures back. Triggers on 'execute the plan', 'build this', 'implement the spec', 'let's build it', 'go ahead and make it', right after a plan is approved with multiple independent pieces, or any request to parallelize the build / fan out agents. Decomposes the plan into parts, orders them into dependency waves, assigns disjoint file ownership, dispatches builders in parallel, and runs a build→test→fix loop per part before reporting for human QA. NOT for QAing an already-built feature (use test-feature), one mechanical change across many files (use codebase-wide-change), or a small single-file edit."
version: 1.0.0
---

# Parallel Plan Execution

The senior-engineer family's engine for **carrying out an approved plan**. The premise: a
plan with several independent parts is slow and error-prone to build one piece at a time in
a single context. A senior engineer instead **decomposes the plan, parallelizes the
independent work across specialists, and pairs each piece with a tester** so defects are
caught next to the code that caused them — while the builder still has the context to fix
them cheaply.

You are the **orchestrator**. You stay in the main loop, keep the whole picture, dispatch
builders and testers, run the feedback loop, and report back. You do not write the feature
code yourself — your job is decomposition, coordination, and judgment.

## When this is worth it (and when it isn't)

Fanning out spends multiple subagents and adds coordination overhead, so use it deliberately.

**Use it when:**
- There's a **plan or spec with multiple parts** to build, and at least some parts are independent.
- The user says "execute/build/implement this", or a plan was just approved.
- The work genuinely benefits from parallelism — several features, layers, or modules.

**Don't use it when:**
- It's a **single-file or one-function change** — just make it, no orchestration.
- The parts are strictly sequential with no parallelism to exploit — build them in order yourself.
- The task is pure QA of something already built → **`test-feature`**.
- The task is one mechanical edit repeated across many files → **`codebase-wide-change`**.

If you're unsure, ask: *would two or three builders working at once actually finish this
sooner and cleaner than I would alone?* If no, skip the fan-out and build directly. It's a
senior-engineer move to **not** over-engineer the process for a small job — say so and just
do the work.

---

## The workflow

### Step 0 — Ground yourself in the plan and the project

You can't parallelize what you don't understand. Before dividing anything:

1. **Pin down the plan.** If a plan/spec already exists (a plan-mode output, a doc, a
   sprint), read it in full. If the user gave a loose ask ("build the settings page"),
   restate the plan as a short ordered list of concrete deliverables and confirm it. Don't
   fan out against a vague target.
2. **Learn the project's ground truth** — `CLAUDE.md` / `AGENTS.md` / `README`, the stack
   and layout (where backend, frontend, tests, types live), how to run and test it (dev
   command, ports, type-check/lint/test commands), and the conventions. The builders and
   testers inherit none of your context, so you must gather what they'll need to be handed.
3. **Sanity-check parallelizability.** Confirm there really are independent parts. If the
   "plan" is actually one tangled change, say so and build it directly instead.

### Step 1 — Decompose into parts and order them into waves

Carve the plan into **coherent parts**, each one a deliverable a single builder can own end
to end (e.g. "the orders API endpoint + service", "the settings page UI", "the DB
migration + shared types"). Then order them by dependency — this is the crux:

- **Foundations first.** Shared types, schema/migrations, API contracts, and core utilities
  that other parts import must land *before* their dependents. Put them in an early wave,
  usually built by **one** builder to avoid races on shared files.
- **Independent parts in parallel.** Parts that don't touch each other's files and don't
  depend on each other's not-yet-built code go in the **same wave** and run concurrently.
- **Integration/glue last.** Wiring, end-to-end flows, and anything that stitches parts
  together goes in a final wave once its inputs exist.

Write down the **wave plan**: which parts are in each wave, what each part delivers, and its
dependencies. A wave is just "the set of parts that can safely run at the same time."

> Keep waves small and honest. If part B imports a type part A defines, they are **not** in
> the same wave — no amount of wishful parallelism makes them independent. Forcing them
> concurrent produces merge conflicts and builders guessing at interfaces that don't exist yet.

### Step 2 — Assign disjoint file ownership

Before dispatching, decide **which files each builder owns**. The rule that prevents the
worst class of bugs: **no two concurrent builders write the same file.** If two parts must
touch one file (a shared router, a barrel export, a config), either:
- put them in **different waves** (one after the other), or
- give **one builder both parts**, or
- have the orchestrator make that one shared edit itself after the builders return.

**Pin the shared contract before fanning out.** When parts in the same wave share an
interface — a type/field shape, an API request/response, CSS class names a renderer and a
stylesheet must agree on — decide that contract *yourself* up front and put it verbatim in
**every** affected builder's brief. This is what lets parts in different files run
concurrently without one guessing at the other's interface: they don't coordinate at
runtime, they both build to the contract you handed them. (In single-file apps where the
coupled work can't be split across files at all, that's your signal to give one builder the
whole coupled part rather than to parallelize it.)

This also protects the user's working tree: builders only create/modify files in their lane,
and **never revert or overwrite changes they didn't make** — yours, the user's, or another
builder's. (See `references/` of the family and the project's own rules; foreign changes are
off-limits.)

### Step 3 — Dispatch the wave's builders in parallel

For each wave, spawn all its builders **in a single message** (multiple Agent calls at once)
so they run concurrently. Pick the agent type that fits each part:
- **`backend-builder`** — APIs, services, business logic, data layer, migrations, seeds.
- **`frontend-builder`** — pages, components, hooks, state, styling, localized UI.
- **`documenter`** — docs/changelog parts, if the plan includes them.
- **`general-purpose`** — anything that doesn't fit the above.

Give each builder a **self-contained brief** — it has none of your context. Read
`~/.claude/skills/parallel-execution/agents/builder-brief.md` and follow it; at minimum the
brief carries the part's scope, its **file ownership** (and explicit out-of-scope files),
the relevant plan/spec text, project conventions and run/test commands from Step 0, the
**acceptance criteria** the part must meet, and the return format. Name each agent so you can
reach it later via `SendMessage` for the fix loop — that preserves its context instead of
re-explaining from scratch.

Wait for a wave to finish (and pass testing, Step 4) before starting the next wave that
depends on it. Independent later-wave parts can start as soon as their own dependencies are
satisfied — you don't have to drain every wave to the last agent if nothing downstream needs it.

### Step 4 — Test each part the moment its builder finishes (the dedicated tester loop)

This loop is the differentiator. **As soon as a builder returns a part, dispatch a dedicated
tester scoped to that part** — don't wait for the whole wave. Use the **`tester`** agent type
(it has browser/Playwright access and can exercise APIs and read source). Keep **at most two
testers running at once**; if more parts land together, queue them so the tester pool stays
at one or two.

Read `~/.claude/skills/parallel-execution/agents/tester-brief.md` and follow it. The tester's
job is narrow and concrete: verify *this part* against *its acceptance criteria* — happy
path, the obvious edge cases, and that it actually runs. The tester **reads source and drives
the live app**; it **does not write production code and never reverts anyone's changes**. It
returns a crisp verdict:

- **PASS** — meets acceptance criteria; note what was checked.
- **FAIL** — with, for each issue: a one-line description, severity (blocker / minor),
  steps to reproduce, and the suspected `file:line` so the builder can act without re-investigating.

### Step 5 — Fix loop: send failures back to the same builder

When a tester returns FAIL on a part, **send the findings back to the builder that built it**
via `SendMessage` (not a fresh agent — the original builder still holds the context for why
the code is the way it is). Hand over the tester's exact findings: the repro, the suspected
location, the severity. The builder fixes, then **re-test the same part** with a tester.

Cap this at **two fix rounds per part.** If a part still fails after two rounds, stop looping
and **surface it to the human as an open blocker** with everything learned — what's wrong,
what was tried, where it likely lives. Burning more rounds on a stuck part usually means the
plan or a dependency is wrong, which is a human call, not a retry.

Only consider a part **done** when a tester has confirmed PASS (or the user has explicitly
accepted a known-incomplete part).

### Step 6 — Optional light integration check

Per-part testing is the core. But when parts interconnect (a UI that calls an API you just
built, a flow that spans modules), once the relevant parts pass individually, run **one light
integration smoke** — a single tester driving the end-to-end flow — to catch seam bugs no
single-part test could see. Keep it light; this is a smoke check, not a full QA pass. (If the
user wants exhaustive end-to-end QA afterward, that's `test-feature`'s job — point them there.)

### Step 7 — Synthesize and hand off for human QA

You orchestrated; now give the human a clear picture. Report:

```markdown
# Plan Execution: <plan name>

## Summary
<1–2 lines: what was built, how many parts, how many waves, overall state>

## Parts
| Part | Builder | Wave | Test verdict | Fix rounds | Notes |
|------|---------|------|--------------|-----------|-------|
| Orders API | backend-builder | 1 | ✅ PASS | 0 | |
| Settings UI | frontend-builder | 2 | ✅ PASS | 1 | fixed validation gap |
| Export flow | backend-builder | 2 | 🚫 OPEN | 2 | still failing — see below |

## Open blockers (need a human decision)
- <part> — <what's wrong, what was tried, suspected location>

## Verified vs. needs human QA
- Verified by testers: <list>
- Recommended human QA before shipping: <list — anything testers couldn't fully exercise>

## Files changed
<by part / builder, so the human can review the diff>
```

Output the report in chat. Don't write it to a file unless asked.

---

## After every run — suggest next steps

End with a brief **"What you can do next:"** (2–4 items): resolve the top open blocker (with
its suspected location), review the diffs for the passed parts, run the project's full test
suite, run `/test-feature <feature>` for exhaustive end-to-end QA, or "ship it" if everything
passed cleanly. Keep it to a bulleted list — the goal is momentum and the clear
highest-impact next action.

---

## Guardrails (senior-engineer judgment, always on)

- **Don't over-spawn.** Two or three well-scoped builders beat eight thrashing on shared
  files. Match the agent count to the plan's real independent parts, not to a target number.
- **Never let agents revert foreign changes.** Disjoint file ownership, and an explicit rule
  in every brief: create/modify only your lane; never undo edits you didn't make. The working
  tree may hold the user's own work or another agent's in-progress changes.
- **Push back before you fan out.** If the plan is half-baked, the parts aren't actually
  independent, or it's too small to parallelize, say so and propose the better path — that's
  the senior move, not silently spawning agents.
- **A part isn't done until a tester confirms it.** "The builder said it's done" is a claim,
  not a verification. The tester loop exists precisely because builders are optimistic.
- **If a builder or tester fails/times out**, report that part as INCOMPLETE with the error;
  don't silently drop it from the plan.

---

## Relationship to the senior-engineer family

- The **`senior-engineer`** persona routes here when the user moves from planning to building.
- **`deep-exploration`** is the read-only counterpart — understand a codebase; this one
  changes it. Run exploration first if the plan touches code you don't yet understand.
- **`test-feature`** is the heavier, standalone QA workflow for an already-built feature; this
  skill's per-part tester loop is lighter and inline. Hand off to `test-feature` when the user
  wants exhaustive end-to-end QA after the build.
- **`codebase-wide-change`** owns the *one-change-everywhere* refactor; reach for it instead
  when the "plan" is really a single mechanical edit repeated across files.
