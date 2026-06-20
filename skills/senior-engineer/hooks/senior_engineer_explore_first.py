#!/usr/bin/env python3
"""PostToolUse:Skill hook — enforces senior-engineer's mandatory "explore first" rule.

Fires every time a skill is invoked; exits silently unless the skill is senior-engineer.
When senior-engineer is engaged, injects a hard, unconditional instruction that the model's
VERY NEXT tool call must be Skill(deep-exploration) — no skip conditions, no inline skim,
and a minimum of three Explore subagents. This closes the gap diagnosed in v3.5.0: Step 0
was the most-emphasized rule in the skill but had no enforcement on the non-plan path, so
the model could improvise inline exploration (and under-fan-out to 2 agents) instead of
performing the actual handoff.

Never blocks; degrades to a no-op on any unexpected payload shape.
"""
import sys, json


def _skill_name(data):
    """Pull the invoked skill's name from the tool payload, tolerating shape drift."""
    ti = data.get("tool_input") or {}
    for key in ("skill", "name", "skill_name"):
        val = ti.get(key)
        if isinstance(val, str) and val:
            return val
    return ""


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)  # never block on a parse error

    if data.get("tool_name") != "Skill":
        sys.exit(0)

    skill = _skill_name(data).strip().lower()
    # Match bare and plugin-namespaced forms (e.g. "some-plugin:senior-engineer").
    if skill.split(":")[-1] != "senior-engineer":
        sys.exit(0)

    context = (
        "ENFORCED — senior-engineer Step 0 (no exceptions): your VERY NEXT tool call MUST be "
        "Skill(deep-exploration). Not your first code tool call — your first tool call, period. "
        "Do NOT read files, run ls/grep/git, spawn Explore agents directly via the Agent tool, "
        "or type any answer/plan before that handoff. This applies to EVERY task — trivial or "
        "substantive, one file or many, code or conceptual; if unsure whether it applies, it "
        "applies. 'I'll explore...' narration followed by inline poking is the exact failure to "
        "avoid: only an actual Skill(deep-exploration) call counts. Once inside it, dispatch a "
        "MINIMUM of three Explore subagents (three is the floor — if the prompt names only two "
        "targets, carve a third section by layer/concern/lens). Then route normally."
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": context,
        }
    }))
    sys.exit(0)


if __name__ == "__main__":
    main()
