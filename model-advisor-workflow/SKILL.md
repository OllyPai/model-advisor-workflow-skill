---
name: model-advisor-workflow
description: Use when routing a coding idea or project task through a stronger Codex planning/review model while Claude Code, DeepSeek, or another execution agent performs implementation; triggers include multi-model workflow, advisor review, milestone review, ask-advisor.sh, context.md handoff, cheap model execution, and expensive model planning.
---

# Model Advisor Workflow

Use this skill to keep expensive model calls focused on planning and review while a cheaper or separate execution agent handles implementation. Codex coordinates; it does not implement the product task.

## Roles

- User: owns the idea, approves the plan, and decides whether advice is worth applying.
- Codex advisor: creates plans and performs read-only milestone reviews.
- Execution agent: writes code, runs tests, updates `.codex-advisor/context.md`, and reads `.codex-advisor/last.md`.

Do not rely on Codex conversation history when the execution agent is Claude Code or another tool. Bridge context through files.

## Hard Handoff Gate

Codex must stop at the handoff boundary. It may:

- install or refresh the advisor workflow files
- inspect the project for planning context
- help refine the idea into an approved plan
- write `.codex-advisor/claude-prompt.md`

Codex must not:

- implement the planned feature or bugfix
- run project build/test commands as part of execution
- edit product source files
- run `./ask-advisor.sh` before Claude Code has completed a milestone

After writing the Claude Code prompt, tell the user to paste or point Claude Code at `.codex-advisor/claude-prompt.md`, then stop. If the user asks Codex to keep implementing, clarify whether they are abandoning this workflow; otherwise keep the handoff boundary.

Important: the return path from Claude Code to Codex is `./ask-advisor.sh`, not the current Codex chat. Claude Code must run that script after a milestone; the script starts a read-only Codex advisor run and writes `.codex-advisor/last.md`.

## Auto-Install In A Project

At the start of a workflow, identify the project root and automatically ensure the advisor files exist there, unless the user explicitly requested read-only planning or no file changes.

Run the bundled installer from the project root:

```bash
bash /Users/oripi/.codex/skills/model-advisor-workflow/scripts/install-advisor-workflow.sh .
```

If the skill is being used from another location, resolve the script path relative to this `SKILL.md`.

The installer is idempotent. It creates missing files and leaves existing project files unchanged:

- `ask-advisor.sh`
- `.codex-advisor/context.md`
- `.codex-advisor/claude-prompt.md`

If the user asks only for planning, skip installation until they approve execution setup.

## Turn An Idea Into A Plan

Ask Codex in read-only mode:

```text
I have this idea:

[idea]

Only plan. Do not edit files. Produce:
1. requirements understanding
2. recommended approach
3. milestones
4. acceptance checks for each milestone
5. execution prompt for Claude Code / DeepSeek
6. what to write into .codex-advisor/context.md at each milestone
```

Have the user approve or revise the plan before sending it to the execution agent.

Once the plan is approved, write the execution prompt to `.codex-advisor/claude-prompt.md` and stop. Do not start implementation in Codex.

The written prompt must include the mandatory advisor checkpoint rules below. Do not weaken them.

## Execution Agent Prompt

Give the execution agent this rule block with the approved plan:

```text
You are the execution agent. Follow the approved plan without expanding scope.

At each milestone:
1. Update .codex-advisor/context.md with User Goal, Current Milestone, Changed Files, Verification, and Open Questions / Risks.
2. Run ./ask-advisor.sh.
3. Read .codex-advisor/last.md.
4. Apply only advice directly relevant to the current goal.
5. Continue to the next milestone.

Mandatory checkpoint:
- Do not mark a milestone complete until steps 1-4 have succeeded.
- If ./ask-advisor.sh fails or .codex-advisor/last.md is missing/stale, stop and ask the user for help.
- Do not continue to the next milestone without a fresh advisor response.

Do not let advisor feedback trigger unrelated refactors.
```

Tell the user to start Claude Code in the project root and provide one of these instructions:

```text
Read .codex-advisor/claude-prompt.md and execute it exactly.
```

or paste the contents of `.codex-advisor/claude-prompt.md` directly into Claude Code.

## Milestone Review Rules

Run `./ask-advisor.sh` only at useful boundaries:

- after initial planning
- after a real milestone
- when blocked on design or risk
- before final handoff

Avoid running it after every small edit. Keep `.codex-advisor/context.md` short and current; it should summarize facts, not copy chats, logs, or full source files.

## Cache And Cost Discipline

This workflow saves money only when expensive-model calls are sparse and focused. Preserve cache-friendliness by keeping static instructions stable and moving changing facts into `.codex-advisor/context.md`.

Do not treat cache hits as guaranteed. The real savings come from using the stronger model for high-value judgment instead of continuous execution.

## Common Mistakes

- Using `codex exec resume --last` when execution happened in Claude Code. This reviews the wrong conversation.
- Letting `.codex-advisor/context.md` grow into a transcript. Summarize instead.
- Treating `.codex-advisor/last.md` as input evidence. It is previous advisor output and should be overwritten by the next run.
- Running the advisor from a parent directory instead of the project root, which weakens git diff review.
- Letting Codex continue past `.codex-advisor/claude-prompt.md` into implementation. That breaks the intended Claude Code handoff.
- Letting Claude Code continue past a milestone without running `./ask-advisor.sh`. That breaks the intended Codex advisor return path.
