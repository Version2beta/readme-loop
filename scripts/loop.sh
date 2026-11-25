#!/usr/bin/env bash
# spec-loop: copy unchanged into a kit. Kit commands live in tasks.json;
# model commands are owner-only environment overrides, never kit settings.
# Each attempt: coder, restore protected paths, format, judge, commit exactly
# what was judged or discard the attempt. --check uses the same judge, no coder
# or formatter. --check-once [ID...] runs format_check, each selected task and
# check once each, for kit iteration on a fixed tree; it is not acceptance.
# Requires bash, git, jq and timeout (or gtimeout).
set -euo pipefail

# Use '-' rather than ':-': an explicitly empty owner override is an error.
CHEAP_CMD=${CHEAP_CMD-'pi --provider anthropic --model claude-haiku-5-5 --thinking high --print --no-session'}
STRONG_CMD=${STRONG_CMD-'pi --provider openai-codex --model gpt-6.1-sol --thinking high --print --no-session'}
STRONGEST_CMD=${STRONGEST_CMD-'pi --provider openai-codex --model gpt-6.1-sol --thinking max --print --no-session'}
MAX_ITER=${MAX_ITER:-60}
MAX_ATTEMPTS=${MAX_ATTEMPTS:-4}
ITER_SECONDS=${ITER_SECONDS:-1200}
JUDGE_TIMEOUT=${JUDGE_TIMEOUT:-300}
TASKS=${TASKS:-tasks.json}

die() { echo "loop: $*" >&2; exit 1; }
command -v jq >/dev/null || die "jq is required"
if command -v timeout >/dev/null; then TIMEOUT=timeout
elif command -v gtimeout >/dev/null; then TIMEOUT=gtimeout
else die "timeout or gtimeout is required"; fi
for setting in CHEAP_CMD STRONG_CMD STRONGEST_CMD; do
  [ -n "${!setting}" ] || die "$setting is empty"
done
for setting in MAX_ITER MAX_ATTEMPTS ITER_SECONDS JUDGE_TIMEOUT; do
  [[ ${!setting} =~ ^[1-9][0-9]*$ ]] || die "$setting must be a positive integer"
done
[ -f "$TASKS" ] || die "$TASKS not found"
CHECK_ONLY=0; ONCE=0
case "${1:-}" in
  --check) CHECK_ONLY=1;;
  --check-once) CHECK_ONLY=1; ONCE=1; shift;;
esac
cfg() { jq -r "$1 // empty" "$TASKS"; }
jq -e 'has("pass_marker") or any(.tasks[]?; has("pass_marker"))' "$TASKS" >/dev/null &&
  die "pass_marker is obsolete; use tasks[].expect full-line regular expressions"
for setting in CHEAP_CMD STRONG_CMD STRONGEST_CMD; do
  jq -e --arg key "$setting" 'has($key)' "$TASKS" >/dev/null && die "$setting is owner-only, not a kit setting"
done
FORMAT_CMD=$(cfg '.format')
FORMAT_CHECK_CMD=$(cfg '.format_check')
CHECK_CMD=$(cfg '.check')
PROTECTED=$(jq -r '(.protected // []) | join("|")' "$TASKS")
PROTECTED="${PROTECTED:+$PROTECTED|}^(${TASKS}|PROMPT\.md|SPEC\.md|scripts/loop\.sh|loop\.sh)$|^STOP$"
ntasks=$(jq '.tasks | length' "$TASKS")
[ "$ntasks" -gt 0 ] || die "no tasks"
task() { jq -r ".tasks[$1].$2 // empty" "$TASKS"; }
for ((i = 0; i < ntasks; i++)); do
  id=$(task "$i" id)
  [[ $id =~ ^[a-zA-Z0-9_-]+$ ]] || die "task $i needs a simple, nonempty id"
  jq -e ".tasks[$i].expect | type == \"array\" and length > 0 and all(.[]; type == \"string\" and length > 0)" "$TASKS" >/dev/null ||
    die "task $id: expect must be a nonempty list of full-line regular expressions"
  while IFS= read -r pattern; do
    rc=0; grep -E -- "$pattern" /dev/null >/dev/null 2>&1 || rc=$?
    [ "$rc" -ne 2 ] || die "task $id: invalid expect regular expression: $pattern"
  done < <(jq -r ".tasks[$i].expect[]" "$TASKS")
done
if [ "$CHECK_ONLY" = 0 ]; then
  untracked=$(git ls-files --others --exclude-standard)
  [ -z "$untracked" ] || die "untracked files (ignore or commit before starting):
$untracked"
  [ -z "$(git status --porcelain)" ] || die "working tree is dirty"
  branch=$(git rev-parse --abbrev-ref HEAD)
  case $branch in main|master|HEAD) die "run on a branch, not $branch";; esac
fi
state=.loop
git check-ignore -q "$state/x" || die "add .loop/ to .gitignore"
mkdir -p "$state"
log() { printf 'loop: %s\n' "$*" | tee -a "$state/loop.log" >&2; }

# All judge commands (including diagnostic probes) are bounded. Keep stdout
# and stderr distinct: only stdout can satisfy an expectation.
run_judge_command() {
  local label=$1 command=$2 rc=0
  "$TIMEOUT" "$JUDGE_TIMEOUT" bash -c "$command" > "$state/$label.stdout" 2> "$state/$label.stderr" || rc=$?
  if [ "$rc" = 124 ]; then
    log "$label timed out after ${JUDGE_TIMEOUT}s: $command"
  elif [ "$rc" != 0 ]; then
    log "$label exited $rc: $command"
  fi
  return "$rc"
}
task_passes() {
  local idx=$1 pattern
  run_judge_command "test.$idx" "$(task "$idx" test)" || return 1
  while IFS= read -r pattern; do
    grep -qxE -- "$pattern" "$state/test.$idx.stdout" || return 1
  done < <(jq -r ".tasks[$idx].expect[]" "$TASKS")
}
judge() {
  local idx=$1 j
  if [ -n "$FORMAT_CHECK_CMD" ]; then
    run_judge_command format_check "$FORMAT_CHECK_CMD" || return 1
  fi
  task_passes "$idx" || return 1
  for ((j = 0; j < idx; j++)); do task_passes "$j" || return 1; done
  if [ -n "$CHECK_CMD" ]; then run_judge_command check "$CHECK_CMD" || return 1; fi
  return 0
}
first_failing() {
  local i
  for ((i = 0; i < ntasks; i++)); do task_passes "$i" || { echo "$i"; return; }; done
  echo -1
}
# Single pass over a fixed tree: the same commands, timeouts and full-line
# expectations as the judge, but earlier tasks are not repeated per task.
if [ "$ONCE" = 1 ]; then
  selected=()
  if [ "$#" = 0 ]; then
    for ((i = 0; i < ntasks; i++)); do selected+=("$i"); done
  else
    for want in "$@"; do
      found=
      for ((i = 0; i < ntasks; i++)); do [ "$(task "$i" id)" != "$want" ] || found=$i; done
      [ -n "$found" ] || die "--check-once: no task $want"
      selected+=("$found")
    done
  fi
  bad=0
  if [ -n "$FORMAT_CHECK_CMD" ]; then
    if run_judge_command format_check "$FORMAT_CHECK_CMD"; then r=pass; else r=FAIL; bad=1; fi
    printf '%-5s %s\n' "$r" format_check
  fi
  for i in "${selected[@]}"; do
    if task_passes "$i"; then r=pass; else r=FAIL; bad=1; fi
    printf '%-5s %s  %s\n' "$r" "$(task "$i" id)" "$(task "$i" title)"
  done
  if [ -n "$CHECK_CMD" ]; then
    if run_judge_command check "$CHECK_CMD"; then r=pass; else r=FAIL; bad=1; fi
    printf '%-5s %s\n' "$r" check
  fi
  exit "$bad"
fi
if [ "$CHECK_ONLY" = 1 ]; then
  bad=0
  for ((i = 0; i < ntasks; i++)); do
    if judge "$i"; then r=pass; else r=FAIL; bad=1; fi
    printf '%-5s %s  %s\n' "$r" "$(task "$i" id)" "$(task "$i" title)"
  done
  exit "$bad"
fi

revert_protected() {
  local f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if git cat-file -e "HEAD:$f" 2>/dev/null; then git checkout -q HEAD -- "$f"; else rm -f -- "$f"; fi
  done < <({ git diff --name-only HEAD; git ls-files --others --exclude-standard; } | grep -E -- "$PROTECTED" || true)
}
commit_attempt() {
  local message=$1 judged_tree=$2
  # Repository hooks must not rewrite the judged files or index at commit.
  git -c core.hooksPath=/dev/null commit -qm "$message" -m "Coder-Command: $cmd"
  [ "$(git rev-parse HEAD^{tree})" = "$judged_tree" ] || die "commit differs from judged tree"
  [ -z "$(git status --porcelain)" ] || die "working tree is dirty after commit"
}
for ((iter = 1; iter <= MAX_ITER; iter++)); do
  idx=$(first_failing)
  if [ "$idx" -lt 0 ]; then log "every task passes"; exit 0; fi
  id=$(task "$idx" id); tier=$(task "$idx" tier)
  n=$(( $(cat "$state/attempts.$id" 2>/dev/null || echo 0) + 1 ))
  echo "$n" > "$state/attempts.$id"
  if [ "$n" -ge "$MAX_ATTEMPTS" ]; then cmd=$STRONGEST_CMD
  elif [ "$n" -gt 1 ] || [ "$tier" = hard ]; then cmd=$STRONG_CMD
  else cmd=$CHEAP_CMD; fi
  {
    cat PROMPT.md
    printf '\n## Task %s: %s\n\nTest command: `%s`\n\n### Current output (tail)\n```\n' \
      "$id" "$(task "$idx" title)" "$(task "$idx" test)"
    # Reuse the search output: no second diagnostic test run.
    tail -n 60 "$state/test.$idx.stdout" "$state/test.$idx.stderr"
    printf '```\n'
    for notes in "$state"/notes.*; do
      [ -s "$notes" ] || continue
      printf '\n### Notes from discarded attempts (%s)\n' "${notes##*/}"
      cat "$notes"
    done
    if [ -s "$state/last.$id.diff" ]; then
      printf '\n### Your previous attempt was discarded. Its diff:\n```\n'
      head -c 20000 "$state/last.$id.diff"; printf '\n```\n'
    fi
  } > "$state/prompt.md"
  log "iter $iter  task $id  attempt $n/$MAX_ATTEMPTS  Coder-Command: $cmd"
  rc=0
  TASK_ID=$id ATTEMPT=$n "$TIMEOUT" "$ITER_SECONDS" bash -c "$cmd" < "$state/prompt.md" > "$state/coder.$id.$n.log" 2>&1 || rc=$?
  [ "$rc" = 124 ] && log "coder timed out after ${ITER_SECONDS}s"
  revert_protected
  ok=1
  if [ -n "$FORMAT_CMD" ]; then run_judge_command format "$FORMAT_CMD" || ok=0; fi
  revert_protected # Formatting must not change protected paths either.
  git add -A
  judged_tree=$(git write-tree)
  if [ "$ok" = 1 ]; then judge "$idx" || ok=0; fi
  git add -A
  if [ "$(git write-tree)" != "$judged_tree" ]; then
    log "judge commands modified the tree"
    ok=0
  fi
  if [ "$ok" = 1 ]; then
    commit_attempt "loop: $id passes (attempt $n)" "$judged_tree"
    rm -f "$state/last.$id.diff"
    log "$id passed"
  else
    { git diff HEAD; git ls-files --others --exclude-standard | sed 's/^/new file: /'; } > "$state/last.$id.diff" || true
    # Keep only added note lines outside the committed tree before discarding.
    git diff --no-ext-diff --unified=0 HEAD -- PROGRESS.md |
      awk '/^\+\+\+/ {next} /^\+/ {print substr($0, 2)}' >> "$state/notes.$id"
    # The clean-start gate establishes that these are attempt-owned changes.
    # Discard the tree changes; saved notes and coder output remain in .loop/.
    git reset -q --hard HEAD
    git clean -qfd
    log "$id failed attempt $n"
    if [ "$n" -ge "$MAX_ATTEMPTS" ]; then
      printf '%s failed %s attempts; see .loop/coder.%s.*.log\n' "$id" "$n" "$id" > STOP
      log "STOP — $id"; exit 2
    fi
  fi
done
log "iteration cap ($MAX_ITER) reached"; exit 3
