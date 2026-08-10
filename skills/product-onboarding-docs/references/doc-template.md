# Doc template & style

Structure distilled from onboarding docs that worked well in production
(a reviewer guide and a manager guide). Follow the skeleton; adapt section count
to the role's actual surface area.

## Skeleton (in order)

```markdown
# <Guide title for the ROLE>                      ← who this is for, in their language

> One-sentence framing: what this role does on the product.
> *Note that screenshots come from a demo env — numbers/names are examples.*

---

<!-- box:start -->                                 ← highlighted quick-start box
## ⭐ Quick start — reading this section is enough to begin

**Your job:** <one sentence>.
<The 3–6 numbered steps of the core loop, with exact button labels and keys.>
**Remember one thing: <the single most important action>.**
<!-- box:end -->

## Table of contents
| Section | Contents |                              ← a 2-column table, §1…§n
| --- | --- |

---

## 1. <Big picture — how a work item flows>       ← optional ASCII diagram of the lifecycle
## 2. <Login & menu map>                          ← table: menu label · path · what it's for
## 3..n-2. <One section per screen/workflow>      ← screenshots + tables + callouts
## n-1. <Scope: what this role does NOT do>       ← phrased as scope, never as "hidden features"
## n. <Keyboard shortcuts>                        ← only if the app has them
```

## Style rules

- **Sections numbered** (`## 3. …`) and cross-referenced as `(§3)`. The TOC rows
  match section titles.
- **Tables for anything enumerable**: menu items (label · path · purpose), form
  fields (field · meaning · default), tabs (tab · use), criteria (checkbox ·
  what it requires · what fails it), shortcut keys (key · effect).
- **Callout blockquotes** (`> **Bold lede.** …`) for warnings, data-safety
  reassurances ("archiving ≠ deletion"), and disambiguations ("content error vs
  rendering error — which button to use").
- **Exact UI strings in bold quotes**: **"Tạo pool mới"**, **"Submit"**. Keys in
  backticks: `R`, `Enter`, `Shift+Enter`. Menu paths as **Group → Item**.
- Distinguish **menu label** from **page title** when they differ; give both once,
  then use whichever the context needs.
- If a button's label changes with state, document both states
  (e.g. *"Start — claim 10 items" when your queue is empty, "Continue review"
  when you hold work*). New users meet the empty state first — lead with it.
- Depth on decision criteria: for each approve/reject checkbox or verdict, say
  what qualifies, what disqualifies, and give one concrete failure example.
- Include a "typical fast rhythm" line where shortcuts exist
  (e.g. *glance → `1` `2` `3` → auto-approve → next*).
- Write prose in the team's working language; keep verbatim UI strings and
  technical identifiers untouched.

## Screenshot placement

- Image line directly after the paragraph describing that UI, then an italic
  caption line naming the exact screen/dialog and what to click:

```markdown
![Alt text describing exactly what the screenshot shows, mentioning the key controls.](images/role-screen.png)
*The **Screen name** (`/path`). Click **"Button"** to …*
```

- Alt text is a full sentence listing the controls visible — it doubles as the
  capture spec and as accessibility text.
- Filenames: kebab-case, role- or screen-prefixed, stable across recaptures
  (`pm-dashboard.png`, `pool-detail-config.png`, `reviewer-grading.png`).

## Update etiquette (when docs already exist)

- Preserve structure, headings and tone; edit surgically.
- Every retained claim was re-verified; every removed claim gets removed because
  the role can no longer see it (don't leave "no longer available" notes).
- Keep image filenames identical when recapturing so references don't churn.
