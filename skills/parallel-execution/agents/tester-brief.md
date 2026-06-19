# Tester dispatch brief

How the orchestrator should brief a dedicated tester (`tester` agent type — it has
Playwright/browser access and can also exercise APIs and read source) to verify **one part**
the moment its builder finishes. The tester's value is being narrow, concrete, and honest:
it confirms the part actually works, and when it doesn't, it hands the builder enough to fix
it without re-investigating.

## What to put in the dispatch prompt

1. **The one part to test — and only that part.** Name the deliverable and its surface (the
   route/URL, the endpoint, the function). Resist scope creep; other parts have their own
   testers. (The cross-part flow is the optional integration smoke in Step 6, briefed separately.)

2. **The acceptance criteria.** The same checkable conditions you gave the builder — these are
   what PASS/FAIL is measured against. The tester should verify each one explicitly.

3. **How to run and reach it.** From your Step 0 grounding: the dev command/port and URL, the
   API base, any **auth/seed credentials** and how sessions work, and the type-check/lint/test
   commands. A tester that can't start the app can't verify anything.

4. **What to exercise.** Happy path against each acceptance criterion, the obvious edge cases
   (missing/invalid input, empty states, boundaries), and a confirmation that the part runs
   without errors (console/network/server logs as relevant).

5. **The boundaries.** State plainly: *read source and drive the live app to verify — but do
   NOT write or edit production code, and never revert or overwrite anyone's changes.* The
   tester reports; the builder fixes. This keeps the working tree clean and the loop honest.

6. **The return format — a crisp verdict.** Tell the tester its final message IS the report.
   Require one of:
   - **PASS** — every acceptance criterion met; list what was checked and how.
   - **FAIL** — for each issue: a one-line description, **severity** (blocker / minor),
     **steps to reproduce**, observed vs. expected, and the **suspected `file:line`** so the
     builder can act immediately. Order issues by severity.

   Ask for the suspected location even when unsure — a best guess saves the builder a search.

## Example brief

> **Test one part: the Orders API (`POST /api/orders`, `GET /api/orders/:id`).**
> Acceptance criteria: 201 + created order on valid input; 400 on missing `customerId`;
> persists to the orders table; `npm run typecheck` and `npm test src/api/orders` pass.
> Run it: `npm run dev` on port 3000; API base `http://localhost:3000/api`. Seed user:
> <creds>. Auth via cookie session.
> Exercise: create a valid order; create with missing `customerId`; fetch the created order
> by id; fetch a non-existent id. Confirm DB persistence. Run the typecheck and the orders tests.
> Boundaries: read source and hit the API to verify; do NOT edit code or revert anything.
> Return: PASS (what you checked) or FAIL — per issue: description, severity, repro,
> observed vs. expected, suspected file:line. Your final message is the report.

## Notes for the orchestrator

- Spawn a tester **per part as it lands**, but keep **at most two testers running at once**;
  queue the rest so the tester pool stays at one or two.
- Feed a FAIL verdict straight back to the **original builder** via `SendMessage` (Step 5),
  then re-dispatch a tester on the fixed part. Cap at two fix rounds, then escalate to the human.
- If the tester can't run the app (missing deps, build broken), that's itself a finding —
  report it as a blocker on that part rather than marking the part untested-and-fine.
