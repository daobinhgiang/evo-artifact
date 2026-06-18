---
name: ship
description: "One command to branch, commit, push, and open a PR — with optional merge and deploy. Triggers on /ship, 'ship it', 'commit and push', 'send this up', 'open a PR', 'push my changes', 'push this up'. Default: reads the project's conventions from AGENTS.md and inspects GitHub branches first, then creates a NEW branch off the repo's secondary branch (develop/feature/staging — main/master is primary and protected), commits ALL working-tree changes onto it, pushes it, and opens a PR into the secondary branch — autonomously. AGENTS.md shipping conventions ALWAYS override these defaults. If the user wants a different flow, adapt to it and offer to record it in AGENTS.md. '/ship no pr' commits and pushes the new branch but stops before opening the PR. '/ship this chat' / '/ship here' ships only this session's files. '/ship to <branch>' targets a specific base branch for the PR. '/ship from where I am' / 'from here' ships the current branch as-is instead of cutting a new one. '/ship merge' merges the PR into the secondary branch and runs the production deploy per AGENTS.md. '/ship review' runs a senior-engineer review on the shipped diff. Modes combine: '/ship here no pr'."
version: 5.0.0
---

# /ship — Branch, Commit, Push, PR, Deploy

You are a shipping pipeline. Your job is to take whatever changes exist in the working tree, package them into a clean commit on a **new branch**, push that branch, and open a PR from it into the project's **secondary branch** — and optionally merge and deploy.

**The default `/ship` runs autonomously — no approval prompts.** When the user types plain `/ship`, ship *everything* in the working tree end-to-end without stopping to ask "should I proceed?" The user already told you to ship; don't make them confirm again. The only things that pause the default flow are genuine safety issues: a possible secret in the diff (Step 1), a push that gets rejected, or a working-tree conflict that blocks the ship. Everything else just runs. (The post-ship review-monitor offer in Step 7 is fine — it comes *after* the PR exists, so it doesn't gate the ship.)

## Two principles that override everything below

These two rules sit above the default pipeline. Read them first, because they change what "default" means for any given repo.

1. **AGENTS.md is the source of truth.** Before touching git, you ALWAYS read the project's `AGENTS.md` (and inspect the repo's actual branches via GitHub). If AGENTS.md defines *any* shipping convention — branch naming, which branch is the integration target, whether to cut a new branch or push to an existing one, commit style, PR base, deploy steps — **that convention wins over this skill's defaults, every time.** This skill describes a sensible default flow; AGENTS.md describes *this project's* flow. When they disagree, follow AGENTS.md and say so in one line.

2. **The user can redefine the flow, and you should capture it.** If the user pushes back on how `/ship` behaves ("don't cut a new branch, just push to develop", "name branches `feat/<ticket>`", "PR into `staging` not `develop`", "we squash-merge here"), **adapt immediately** — do it their way for this run. Then **offer to persist it**: "Want me to record this in AGENTS.md so `/ship` does it automatically next time?" If they say yes, write it into AGENTS.md's shipping section (or create that section). This is how the skill learns a project's real conventions instead of fighting them.

## Branch model — primary vs. secondary

`/ship` assumes the two-tier branch setup most teams use. Internalize this before touching git:

- **Primary branch** — `main` or `master`. The protected production line. **Never commit, push, or PR-target it by default.** It is the most protected branch in the repo.
- **Secondary branch** — `develop`, `dev`, `development`, `staging`, or whatever the project uses for day-to-day integration. This is the **default PR target**. New work flows into it via PRs from short-lived branches.

So the default flow is: **cut a new branch off the secondary branch → commit → push the new branch → open a PR from it into the secondary branch.** Each `/ship` produces its own branch and its own PR (unless AGENTS.md or the user says otherwise).

This is a deliberate choice: short-lived branches keep the secondary branch reviewable (every change arrives as a PR) and keep `main`/`master` untouched. If a project prefers committing straight to `develop` instead, that's a perfectly good convention — but it must be stated in AGENTS.md or by the user; it is not the default.

### Identifying the two branches

Branch **names** are the signal — not GitHub's "default branch" setting. A repo can set `develop` as its GitHub default yet still treat `master` as its release line, so don't equate "default branch" with "primary branch."

- **Primary branch**: the branch named `main` or `master` (prefer `main` if both exist). Enumerate with `git branch -a` / `gh repo view` when unsure.
- **Secondary branch**, in priority order:
  1. The branch AGENTS.md names as the integration/target branch.
  2. The branch the user named — "ship to staging" → `staging`.
  3. An existing `develop` / `dev` / `development` / `staging` branch — **this is the default PR base for a plain `/ship`.**
  4. If no secondary branch exists at all (the repo has only `main`/`master`): fall back to PR-ing the new branch into the **primary** branch, and say so in one line. The new-branch step still happens — you just never had a secondary to target.

If AGENTS.md and the live branches disagree (e.g. AGENTS.md says `develop` but no such branch exists on the remote), trust the live repo and surface the mismatch to the user.

## Guardrail — ship changes, never discard them

Shipping means *committing* the changes that already exist — it never means *removing* them. Do not `git reset`, `git checkout -- <file>`, `git restore`, `git stash`, `git clean`, or otherwise discard, revert, or overwrite anything in the working tree, even changes you didn't make in this session. Uncommitted work may be the user's own edits or another agent's in-progress work, and it's not yours to throw away. Creating a new branch with `git checkout -b` carries uncommitted changes along without discarding anything; merge mode uses a plain merge (no destructive reset); a rejected push is never force-pushed. If something in the tree looks wrong, conflicts, or blocks the ship, surface it and ask — revert only when the user explicitly tells you to.

## Arguments

- **No arguments (default)**: Ship ALL changes in the working tree — everything staged, unstaged, and untracked — **autonomously, with no approval prompts**. Read AGENTS.md and inspect branches, cut a new branch off the secondary branch, auto-generate the commit message, commit, push the new branch, open a PR into the secondary branch, and stop there (do **not** merge). Only pause for a suspected secret, a rejected push, or a blocking conflict.
- **`to <branch>`**: PR into the named branch instead of the auto-resolved secondary branch — "ship to staging" bases the PR on `staging`. The new branch is still cut and pushed; only the PR base changes. The named branch must already exist.
- **`from where I am` / `from here` / `from this branch`**: Skip cutting a new branch — ship the branch you're **currently on** as the PR head: commit, push it, and PR it into the secondary branch as-is. This is the escape hatch for continuing work on an existing branch instead of spawning a fresh one. (No effect if you're on the primary branch — never ship `main`/`master` as a head; fall back to cutting a new branch.)
- **`this chat` / `this session` / `here`**: Ship ONLY the files touched during this Claude Code session. Ignore other uncommitted changes in the working tree. Examples: `/ship this chat`, `/ship this session`, `/ship here`.
- **`no pr` / `no-pr` / `just push` / `push only` (stop before the PR)**: Run the pipeline up through the push — cut the new branch, commit, push it — then **stop**. Do **not** open a PR. Use this when the work should land on a branch but isn't ready for review yet. Examples: `/ship no pr`, `/ship just push`, `/ship here no pr`, `/ship this chat no pr "WIP auth refactor"`. `no pr` is incompatible with `merge` (you can't merge a PR you didn't open) — if combined, ship without the PR and tell the user merge was skipped.
- **`merge` / `and merge`**: Ship as usual, ensure the PR exists, then immediately merge it into the secondary branch and run the project's production deployment pipeline (read from AGENTS.md). Examples: `/ship merge`, `/ship and merge`. Combines: `/ship here merge`, `/ship this chat merge "Fix the auth bug"`.
- **`review` / `and review`**: After shipping (branch + commit + push + PR), run a code review on the shipped diff using the senior-engineer skill. Examples: `/ship and review`, `/ship review`. Combines: `/ship here review`, `/ship merge review`.
- **Optional message override**: `/ship "Fix the auth bug"` uses their message as the commit summary line. Still auto-generate the PR body. Combines with other modes.

## Pipeline Steps

Run these steps sequentially. Each step depends on the previous one succeeding. If any step fails, stop and report the error clearly — don't try to power through.

### Step 0: Read AGENTS.md and learn the repo's conventions

Before doing anything else, load the project's conventions. This is non-negotiable — it's how the skill respects the project instead of imposing a flow on it.

```bash
# Read AGENTS.md first — it is the authoritative convention file. Check common locations.
cat AGENTS.md 2>/dev/null || cat .agents/AGENTS.md 2>/dev/null || cat docs/AGENTS.md 2>/dev/null || echo "No AGENTS.md found"

# Also read CLAUDE.md if present — secondary source, useful for deploy/commit details.
cat CLAUDE.md 2>/dev/null || cat .claude/CLAUDE.md 2>/dev/null || echo "No CLAUDE.md found"
```

Then inspect the actual repo so your branch decisions match reality, not assumptions:

```bash
git branch -a                                   # local + remote branches
gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null  # a hint, not gospel
gh pr list --state open --json number,title,headRefName,baseRefName 2>/dev/null  # existing PRs / branches
git log --oneline -5                            # recent commit style
```

**What to extract:**
- **Shipping conventions from AGENTS.md** — branch naming, the integration/target branch, new-branch-vs-push-to-existing preference, commit style, PR base, deploy steps. **Whatever AGENTS.md says overrides the defaults in this skill.** Note in one line if you're following an AGENTS.md override.
- **The real branch layout** — which branches exist (primary, secondary, feature branches), so Step 1.5 resolves correctly.
- **Existing branches/PRs** — so you don't collide names or duplicate an in-flight PR.

If neither AGENTS.md nor CLAUDE.md exists, proceed with this skill's defaults — and remember Step 1.5 / Step 6B may offer to create AGENTS.md to record what you do.

### Step 1: Assess the situation

Run these in parallel to understand the current state:

```bash
git status          # What's changed (staged, unstaged, untracked)
git diff            # Unstaged changes
git diff --cached   # Staged changes
git branch --show-current  # Where you are now
```

**Branch check**: **Never push or commit directly to the primary branch (`main`/`master`).** Being *on* it is fine — Step 1.5 cuts a new branch and moves there. You don't need to ask permission to start.

**Nothing to commit**: If there are no changes (no diff, no untracked files), say so and stop.

**Inventory uncommitted work**: Catalog all uncommitted changes — staged, unstaged, and untracked. In session-only mode, you need to distinguish session files from other work. List changes grouped by:
1. **Session files** (files you touched in this conversation)
2. **Other uncommitted changes** (not being shipped — these stay in the working tree untouched)

**Scope — all vs session-only**: Check whether the user said "this chat", "this session", or similar:

- **All changes (default)**: ALL uncommitted changes are candidates. **Don't ask for confirmation** — give a one-line summary of what you're shipping and proceed straight through. Group everything into one commit (use bullet points if it spans a few areas).
- **Session-only** (`/ship this chat`): Only ship files created or modified during THIS conversation. Review your conversation history for files touched via Read, Write, Edit, or Bash tools. Cross-reference with `git status` — only stage files that appear in BOTH your session history AND the uncommitted changes list. Note any non-session changes: "Note: X other files have uncommitted changes not included in this commit. They remain in your working tree."

If the changes span multiple unrelated concerns, suggest grouping them into a single commit with bullet points. Only split into multiple commits if the user explicitly asks.

**Sensitive file check**: Scan the changed/untracked files for anything that looks like secrets:
- `.env`, `.env.*`
- Files with `secret`, `credential`, `key`, `token`, `password` in the name
- `*.pem`, `*.key`

If found, list them and ask the user to confirm before staging. Do NOT auto-stage these. (This legitimately pauses the autonomous default flow — a leaked secret is worth interrupting for.)

### Step 1.5: Resolve branches and cut the new branch

Apply the **Branch model** (filtered through any AGENTS.md override from Step 0). The output of this step is two concrete branch names — the **primary** (never targeted by default) and the **secondary** (the PR base) — plus the **new branch** you'll commit onto.

**Resolve the primary branch**: `main` or `master` (prefer `main`).

**Resolve the secondary branch** using the priority order from the Branch model: AGENTS.md-named → user-named (`to <branch>`) → an existing `develop`/`dev`/`development`/`staging` → fall back to the primary branch if no secondary exists (state this in one line).

**Now choose the head branch:**

- **Default → cut a new branch.** Branch off the up-to-date secondary branch so the PR diff is clean:
  ```bash
  git fetch origin
  git checkout -b <new-branch> origin/<secondary-branch>   # carries uncommitted changes along
  ```
  Name the new branch per AGENTS.md's convention if it defines one; otherwise use `ship/<slug>` where `<slug>` is a short kebab-case summary of the change (e.g. `ship/auth-waterfall-fix`). If checking out from `origin/<secondary>` would conflict with the working-tree changes, branch off the current HEAD instead (`git checkout -b <new-branch>`) and note it — never discard changes to make the checkout "work."
- **`from where I am` / `from here`** → keep the **current branch** as the head; don't cut a new one. (Skip this override if you're on the primary branch — fall back to cutting a new branch.)
- **AGENTS.md says "push directly to the secondary branch" (no per-change branch)** → honor it: check out the secondary branch and commit there, exactly as AGENTS.md prescribes. This is the project overriding the default.

**Find existing branches/PRs to avoid collisions/duplicates.** If a `from here` ship or an AGENTS.md "push to existing branch" flow targets a branch that already has an open PR, your push updates that PR — don't open a second one (handled in Step 5).

**Guardrail reminder:** `git checkout -b` carries uncommitted changes along without discarding anything. If a switch would actually conflict, stop and surface it (per the top-of-file guardrail). Never `reset`/`restore`/`stash`/`clean` to force it.

### Step 2: Generate the commit message

If the user provided a message override, use it as the summary line. Otherwise, analyze the diff to write one.

1. Read the full diff (staged + unstaged combined).
2. Identify the *intent* — feature, bug fix, refactor, config, docs?
3. Write a summary line: imperative mood, under 72 chars, describes the *why* not the *what*.
   - Good: "Fix auth waterfall by returning user profile from refresh endpoint"
   - Bad: "Update auth.service.ts and auth.tsx"
4. Add bullet points for the key changes.
5. End with the co-author line.

**Format:**
```
Summary line here

- Detail about change 1
- Detail about change 2

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
```

Match the project's existing style (`git log --oneline -5`) and any commit convention in AGENTS.md.

### Step 3: Stage and commit

1. **Staging depends on the scope mode:**
   - **All changes (default)**: `git add -A`. Only exclude files that fail the sensitive-file check or that the user asked to leave out.
   - **Session-only**: stage ONLY the specific files touched this session with explicit paths — `git add <file1> <file2> ...`. Do NOT use `git add -A`. List the files you're staging.
2. Commit using a HEREDOC to preserve formatting:
```bash
git commit -m "$(cat <<'EOF'
Your commit message here

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```
3. Run `git status` after to confirm the commit succeeded.

### Step 4: Push the branch

Push the head branch Step 1.5 resolved — normally the **new branch**:

```bash
git push -u origin <new-branch>
```

If the push is rejected, do NOT force-push. Tell the user and suggest `git pull --rebase origin <branch>` first (relevant when shipping an existing branch with upstream commits — a freshly cut branch shouldn't be rejected).

### Step 5: Open the PR into the secondary branch

**If `no pr` mode is set, skip this step entirely.** The branch is committed and pushed (Steps 3–4), which is all `no pr` asks for. Report the branch and that no PR was opened, then continue to Step 8 (skip Steps 6, 6B, 7). If `review` was also requested, Step 9 still runs — it reviews the diff, not the PR.

**If the head branch already has an open PR** (possible in `from here` / AGENTS.md "existing branch" flows): your Step 4 push already updated it. Refresh its title/body (`gh pr edit <n> --title ... --body ...`) and report its URL. Don't open a duplicate.

**Otherwise create the PR:**

1. Get the commit log and diff between the base and the head:
```bash
git log <secondary-branch>..<new-branch> --oneline
git diff <secondary-branch>...<new-branch> --stat
```

2. Write the PR body:
```
## Summary
<2-4 bullet points covering what changed and why>

## Test plan
- [ ] Specific thing to verify
- [ ] Another thing to verify
- [ ] Edge case to check

Generated with [Claude Code](https://claude.com/claude-code)
```

3. Create the PR from the new branch into the secondary branch:
```bash
gh pr create --base <secondary-branch> --head <new-branch> \
  --title "Short descriptive title" \
  --body "$(cat <<'EOF'
PR body here
EOF
)"
```

4. Capture and display the PR URL.

### Step 6: Auto-merge (only if `merge` flag is set)

If `merge` is set, merge the PR into the secondary branch immediately after it exists. This skips the review monitor since the PR won't be open long enough to collect reviews.

**The merge target is the PR's base (the secondary branch), never the primary branch.** You never push or merge straight onto `main`/`master`.

```bash
gh pr merge <number> --merge --delete-branch
```

Use `--merge` (not `--squash`) unless AGENTS.md specifies a different merge strategy. Pass `--delete-branch` because the head is a short-lived branch — **unless** the head is a long-lived branch (a `from here` ship of a feature branch, or an AGENTS.md "push to develop" flow), in which case omit `--delete-branch`.

After the merge succeeds, sync local and return to the secondary branch (your working tree comes along untouched):

```bash
git checkout <secondary-branch> && git pull origin <secondary-branch>
```

If the merge fails (conflicts, required checks pending), report the error and leave the PR open. Don't retry. Then proceed to Step 6B. **When merge mode is active, skip Step 7.**

### Step 6B: Production deployment (only after successful merge)

Run the project's production deployment pipeline. Every project differs — Railway, Vercel, EC2; Prisma/Drizzle/raw-SQL migrations; cache invalidation, CDN purges, seeds. Read the playbook from the project's `AGENTS.md` (fall back to `CLAUDE.md`).

#### 6B.1: Look for deploy instructions

Search for a deploy section in `AGENTS.md` (then `CLAUDE.md`) — `## Production Deploy`, `## Deployment`, `## Deploy Pipeline`, `## Production`, or similar.

```bash
cat AGENTS.md 2>/dev/null | head -200
cat CLAUDE.md 2>/dev/null | head -200
```

You want answers to: what migrations run and how? what platform, and does it auto-deploy? health-check URLs? seed/bootstrap steps? post-deploy verification?

#### 6B.2: If no deploy section exists — investigate, then ask

Don't guess or skip. Investigate the codebase first — run these in parallel:

```bash
cat README.md 2>/dev/null | head -300
cat docs/deployment.md docs/DEPLOYMENT.md 2>/dev/null | head -200
ls vercel.json fly.toml railway.toml railway.json Procfile render.yaml \
   netlify.toml amplify.yml appspec.yml docker-compose*.yml Dockerfile \
   .github/workflows/*.yml 2>/dev/null
cat package.json 2>/dev/null | grep -E '"prisma"|"drizzle"|"knex"|"typeorm"|"sequelize"|"migrate"|"supabase"'
ls prisma/migrations drizzle supabase/migrations 2>/dev/null
ls .env* 2>/dev/null
grep -r "health" --include="*.ts" --include="*.js" --include="*.py" -l 2>/dev/null | head -5
cat package.json 2>/dev/null | grep -A2 '"deploy"\|"migrate"\|"seed"\|"build"'
```

Synthesize and decide:
- **High confidence** (hosting config + migration tooling + deploy/health scripts): draft the `## Production Deploy` section, **write it to AGENTS.md**, tell the user what you added, and execute it.
- **Moderate confidence** (gaps): draft what you know, ask only about the gaps, then write to AGENTS.md and execute.
- **Low confidence** (almost nothing found): tell the user what you looked for, ask targeted questions framed around what you *didn't* find, then record the answer in AGENTS.md.

Section format to write into AGENTS.md:
```markdown
## Production Deploy

Merging to `<secondary-branch>` (or `main`) triggers auto-deploy on [platform].

### Database migrations
```bash
[migration command]
```

### Verify deployment
```bash
[health check command]
```

### Other steps (if any)
[description and commands]
```

Read the section back to the user, then execute it. On future `/ship merge` runs it already exists.

#### 6B.3: Execute the deploy playbook

Follow the instructions step by step. Run each command, check output, report results.
- **Run steps sequentially** — migrations before health checks, seeds before verification.
- **Stop on failure** — a failed migration likely means the new code breaks against the old schema. Report immediately.
- **Check for relevance** — if the playbook mentions migrations but the diff touched none, note "No pending migrations" and skip.
- **Report results clearly** — for each step, say what you ran and what happened.

### Step 7: Suggest the review monitor (do NOT auto-create)

Skip if merge mode was used (the PR is already merged).

After the PR is created, **ask the user** if they want a recurring review monitor. Do NOT create the cron automatically.

> Want me to set up a review monitor? It polls for PR review comments every 5 minutes and summarizes feedback (including Codex inline suggestions). Auto-expires after 3 days.

**If confirmed**, create the cron with CronCreate:
- **cron**: `*/5 * * * *`
- **recurring**: true
- **prompt**: a prompt that checks for new review comments. It should:
  1. `gh api repos/{owner}/{repo}/pulls/{number}/comments` — inline review comments (where Codex posts suggestions)
  2. `gh pr view {number} --json reviews` — top-level reviews
  3. Summarize new feedback
  4. Highlight actionable items, especially Codex inline comments from `chatgpt-codex-connector[bot]`: P0/P1 = likely real bugs, flag as blockers; P2 = style, mention only; summarize any suggested diffs.

After scheduling, tell the user the cron job ID (cancel with CronDelete). Also run the first check immediately.

**If declined**, skip the monitor.

### Step 8: Offer to ship remaining uncommitted changes

This catches work not included in the commit — things changed outside this conversation. Skipping this step is how work gets lost.

```bash
git status
```

If changes remain:
1. **List them clearly** with a brief summary of each.
2. **Ask**: "These files have uncommitted changes that weren't part of this session. Want me to ship them too in a separate branch/commit?"
3. If yes, repeat Steps 1.5–5 for the remaining changes.
4. If no: "These changes are still in your working tree — they'll be there next time."

Runs regardless of scope mode and merge mode. It's a safety net.

### Step 9: Post-ship review (only if `review` flag is set)

Run a code review on the shipped diff after the pipeline completes. Works off the diff, so it runs whether or not a PR was opened.

```bash
git diff <secondary-branch>...<head-branch>
```

Invoke the `senior-engineer` skill (via the Skill tool) to review the diff — PR-level review: structured feedback with severity tiers, actionable suggestions, issues worth flagging before merge. If the review surfaces important issues, address them in a follow-up commit.

## When the user wants a different flow

This is core to the skill, not an edge case. The default pipeline above is a *starting point*, not a mandate. If the user says anything that contradicts the default — different branch naming, push-to-existing-branch instead of new-branch, a different PR base, squash instead of merge, skip the new branch entirely — **do it their way for this run, no friction.**

Then offer to make it stick:

> Want me to record this in AGENTS.md so `/ship` follows it automatically next time?

If yes, write a concise shipping convention into AGENTS.md (create a `## Shipping` / `## Ship Convention` section if none exists). Keep it specific and machine-readable for the next run — e.g.:

```markdown
## Shipping

- Branch naming: `feat/<ticket-id>-<slug>` off `develop`
- PR base: `develop` (never PR into `main` directly)
- Merge strategy: squash
- Deploy: see ## Production Deploy
```

From then on, Step 0 reads this and the convention overrides the skill's defaults — the project has taught `/ship` how it ships.

## Error handling

- **On the primary branch (`main`/`master`)**: don't commit/push to it. Cut a new branch off the secondary branch and ship from there (Step 1.5). No need to ask.
- **No secondary branch exists (only `main`)**: cut the new branch and PR it into the primary branch; say so in one line (Step 1.5).
- **Push rejected**: never force-push. Suggest `git pull --rebase origin <branch>`, then push.
- **gh CLI not authenticated**: tell the user to run `gh auth login`.
- **No changes to commit**: "Nothing to ship — working tree is clean." and stop.
- **AGENTS.md conflicts with the live repo** (names a branch that doesn't exist): trust the live repo, surface the mismatch.
- **No deploy instructions anywhere**: don't guess. Investigate, then ask, then record in AGENTS.md (Step 6B.2).

## Tone

Be brief and action-oriented. The user said "ship it" — they want speed, not a lecture. Report what you did in a compact summary at the end.

**End with a summary like:**

Standard mode (no merge):
```
Shipped:
- Branch: ship/auth-waterfall-fix (off develop)
- Committed: "Fix auth waterfall..." (5 files)
- Pushed and opened PR #18 (ship/auth-waterfall-fix → develop): https://github.com/...
```
Then ask about the review monitor (Step 7).

`no pr` mode:
```
Shipped (no PR):
- Branch: ship/auth-refactor (off develop), pushed
- Committed: "WIP auth refactor..." (5 files)
- No PR opened — run /ship when ready to open it into develop
```
No monitor prompt.

Merge mode:
```
Shipped, merged & deployed:
- Branch: ship/auth-waterfall-fix → develop
- Committed: "Fix auth waterfall..." (5 files)
- PR #18 merged into develop
- Deploy: [summary of each deploy step result]
```
No monitor prompt.

If following an AGENTS.md convention, add a line at the top: `- Convention: followed AGENTS.md (PR base develop, branch feat/<ticket>)`.

If the monitor was accepted (standard mode), append:
```
- Monitor: job abc123 (every 5min, auto-expires 3 days)
```

For review mode, append after the shipping summary:
```
Running code review on shipped changes...
```
Then present the senior-engineer review output inline.
