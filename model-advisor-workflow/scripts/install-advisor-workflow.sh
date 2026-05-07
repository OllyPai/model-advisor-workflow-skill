#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
OUTPUT_DIR="$TARGET_DIR/.codex-advisor"
ADVISOR_SCRIPT="$TARGET_DIR/ask-advisor.sh"
CONTEXT_FILE="$OUTPUT_DIR/context.md"
CLAUDE_PROMPT_FILE="$OUTPUT_DIR/claude-prompt.md"

mkdir -p "$OUTPUT_DIR"

if [ -e "$ADVISOR_SCRIPT" ]; then
  SCRIPT_STATUS="kept existing"
else
  SCRIPT_STATUS="created"
  cat > "$ADVISOR_SCRIPT" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

ADVISOR_MODEL="${ADVISOR_MODEL:-gpt-5.5}"
OUTPUT_DIR=".codex-advisor"
OUTPUT_FILE="$OUTPUT_DIR/last.md"
CONTEXT_FILE="${ADVISOR_CONTEXT:-$OUTPUT_DIR/context.md}"

mkdir -p "$OUTPUT_DIR"

if [ ! -f "$CONTEXT_FILE" ]; then
  printf 'Advisor context file not found: %s\n' "$CONTEXT_FILE" >&2
  printf 'Create or update it from the execution agent before running this script.\n' >&2
  exit 1
fi

printf '%s\n' "You are a read-only advisor. The execution agent may be Claude Code + DeepSeek or another tool; do not rely on Codex conversation history.

Read ${CONTEXT_FILE}, then inspect the current project in read-only mode. If this is a git repository, check git status and git diff. If it is not a git repository, review based on the context file and relevant files.

Do not treat ${OUTPUT_FILE} as current input or evidence; it is previous advisor output and will be overwritten after this run.
Do not treat AGENTS.md, CLAUDE.md, or memory context as factual evidence for this review; they are behavior constraints only. Factual evidence is limited to ${CONTEXT_FILE}, read-only checks, and the current user request.

Output:
1. goal alignment
2. over-engineering risk
3. likely bugs, missing tests, or risks
4. the smallest next action

Do not edit files. Keep the advice concise and actionable." \
| codex exec \
  --skip-git-repo-check \
  --sandbox read-only \
  -m "$ADVISOR_MODEL" \
  -o "$OUTPUT_FILE" \
  -

printf '\nAdvisor output written to %s\n' "$OUTPUT_FILE"
SCRIPT

  chmod +x "$ADVISOR_SCRIPT"
fi

if [ ! -e "$CONTEXT_FILE" ]; then
  CONTEXT_STATUS="created"
  cat > "$CONTEXT_FILE" <<'CONTEXT'
# Advisor Context

## User Goal

[Write the user-approved goal.]

## Current Milestone

[Write the current milestone and what has been completed.]

## Plan

[Write the short approved plan or current next steps.]

## Changed Files

- [path]: [why it changed]

## Verification

- [command]: [result]

## Open Questions / Risks

- [risk or uncertainty]
CONTEXT
else
  CONTEXT_STATUS="kept existing"
fi

if [ ! -e "$CLAUDE_PROMPT_FILE" ]; then
  CLAUDE_PROMPT_STATUS="created"
  cat > "$CLAUDE_PROMPT_FILE" <<'PROMPT'
# Claude Code Execution Prompt

You are the execution agent. Use the approved plan below and do not expand scope.

## Approved Plan

[Paste the user-approved plan here.]

## Execution Rules

1. Implement only the current milestone.
2. When the milestone implementation and local verification are done, update `.codex-advisor/context.md` with User Goal, Current Milestone, Changed Files, Verification, and Open Questions / Risks.
3. Run `./ask-advisor.sh`. This is the return path to Codex; it starts a read-only Codex advisor run and writes `.codex-advisor/last.md`.
4. Read `.codex-advisor/last.md`.
5. Apply only advice directly relevant to the current goal.
6. Do not mark the milestone complete until steps 2-5 have succeeded.
7. If `./ask-advisor.sh` fails or `.codex-advisor/last.md` is missing/stale, stop and ask the user for help.
8. Continue to the next milestone only after the current milestone is verified and the advisor checkpoint is complete.
9. Do not let advisor feedback trigger unrelated refactors.
PROMPT
else
  CLAUDE_PROMPT_STATUS="kept existing"
fi

printf 'Advisor workflow ready in %s\n' "$TARGET_DIR"
printf 'ask-advisor.sh: %s\n' "$SCRIPT_STATUS"
printf '.codex-advisor/context.md: %s\n' "$CONTEXT_STATUS"
printf '.codex-advisor/claude-prompt.md: %s\n' "$CLAUDE_PROMPT_STATUS"
printf 'Next: update %s, then run %s\n' "$CONTEXT_FILE" "$ADVISOR_SCRIPT"
