# Deep-exploration fallback

Use this when no `deep-exploration` skill exists in the session. Same
divide-and-conquer idea, self-contained.

## Method

1. **Bird's-eye map first** (yourself, cheap): repo root listing, top-level
   READMEs/AGENTS files, service boundaries (frontend vs backend), routing
   entrypoints, docs folders. Output: a one-page mental map of where things live.

2. **Split into sections and fan out read-only subagents** — minimum three,
   aim for more. Each gets a narrow charter, the bird's-eye map, and returns a
   structured report (facts + file paths as evidence, no speculation).
   Standard charters for an onboarding-doc job:

   - **Existing docs hunter** (always spawn this one): find prior onboarding or
     user docs in any language — `docs/**`, `*.md` with role/guide/manual-like
     names, `images/` folders with UI screenshots, docx/pdf artifacts, doc build
     scripts. Report their structure and an itemized list of every UI claim
     (labels, paths, workflows) for later verification.
   - **Access & visibility mapper**: route definitions + guards, nav/sidebar
     config, permission/role constants, feature flags, per-view visibility
     lists. Deliverable: for the target role, the definitive page-by-page
     "can see / cannot see" table, with file evidence. Note anywhere the API is
     more permissive than the UI (the UI wins for docs).
   - **Workflow tracer** (one per major flow): the role's end-to-end user
     stories — screens, states, buttons, dialogs, validations, empty states,
     keyboard shortcuts, toasts/error strings. Extract exact UI strings from
     component code/i18n files.
   - **Context scout**: what the product is, adjacent pipeline steps around this
     role's work (what happens before their input arrives, where their output
     goes), team conventions (doc language, naming), and any environment info
     (test/staging URLs, seed accounts).

3. **Synthesize** the reports into one model: role surface map + workflow list +
   existing-doc inventory + open questions. Contradictions between subagent
   reports get resolved by reading the disputed file yourself.

4. **Verify against the live app** (this part is never optional, skill or no
   skill): log in as the role, walk every page the map says is visible, and
   annotate the map with observed labels and mismatches. Code tells you what
   *might* render; only the running app tells you what the reader sees.

## Subagent briefing tips

- Read-only; report facts with `path:line` evidence.
- Give each agent the bird's-eye map so they don't re-derive it.
- Ask for exact strings, not summaries ("button label is `Tạo pool mới`", not
  "a create button").
- Cap scope: one charter each; anything off-charter goes in a "flagged for
  others" list instead of being chased.
