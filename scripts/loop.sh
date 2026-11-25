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
# Empty numeric overrides are errors, not defaults: '-' keeps an explicit empty value.
MAX_ITER=${MAX_ITER-60}
MAX_ATTEMPTS=${MAX_ATTEMPTS-4}
ITER_SECONDS=${ITER_SECONDS-1200}
JUDGE_TIMEOUT=${JUDGE_TIMEOUT-300}
TASKS=${TASKS-tasks.json}
# Fixed, not an owner setting: seconds between SIGTERM and SIGKILL when a
# timed command ignores SIGTERM. Without it, timeout waits indefinitely.
KILL_GRACE=5

die() { echo "loop: $*" >&2; exit 1; }
command -v jq >/dev/null || die "jq is required"
if command -v timeout >/dev/null; then TIMEOUT=timeout
elif command -v gtimeout >/dev/null; then TIMEOUT=gtimeout
else die "timeout or gtimeout is required"; fi
for setting in CHEAP_CMD STRONG_CMD STRONGEST_CMD; do
  [[ ${!setting} =~ [^[:space:]] ]] || die "$setting is empty or blank"
done
for setting in MAX_ITER MAX_ATTEMPTS ITER_SECONDS JUDGE_TIMEOUT; do
  [[ ${!setting} =~ ^[1-9][0-9]*$ ]] || die "$setting must be a positive integer"
done
[ -f "$TASKS" ] || die "$TASKS not found"
CHECK_ONLY=0; ONCE=0
case "${1:-}" in
  --check) [ "$#" = 1 ] || die "--check takes no task ids"; CHECK_ONLY=1;;
  --check-once) CHECK_ONLY=1; ONCE=1; shift;;
  '') [ "$#" = 0 ] || die "unexpected empty argument";;
  *) die "unknown argument: $1";;
esac
# Reject malformed kits before creating state or executing any kit command.
# Validation uses a fixed number of jq calls at startup, never per task or judge.
jq -e '
  type == "object" and
  (.tasks | type == "array" and length > 0 and all(.[];
    type == "object" and
    (.id | type == "string" and length > 0) and
    (.test | type == "string" and test("\\S")) and
    ((.tier // "normal") | . == "normal" or . == "hard") and
    ((.title // "") | type == "string"))) and
  ([.format, .format_check, .check] | all(.[]; . == null or (type == "string" and test("\\S")))) and
  ((.protected // []) | type == "array" and all(.[]; type == "string" and length > 0))
' "$TASKS" >/dev/null || die "invalid kit: expected nonempty tasks with string id/test, normal/hard tier, nonblank commands (or none), and string protection patterns"
jq -e '[.tasks[].id] | length == (unique | length)' "$TASKS" >/dev/null ||
  die "duplicate task ids"
while IFS= read -r pattern; do
  rc=0; grep -E -- "$pattern" /dev/null >/dev/null 2>&1 || rc=$?
  [ "$rc" -ne 2 ] || die "invalid protected regular expression: $pattern"
done < <(jq -r '.protected[]?' "$TASKS")
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
PROTECTED="${PROTECTED:+$PROTECTED|}^(PROMPT\.md|SPEC\.md|scripts/loop\.sh|loop\.sh)$|^STOP$"
# The kit's own task file is protected by exact repository-relative name, not
# by interpolating it into a regular expression: tasks+v2.json is literal, and
# ./tasks.json or an absolute path inside the repository names tasks.json.
tasks_rel=$TASKS
while [ "${tasks_rel#./}" != "$tasks_rel" ]; do tasks_rel=${tasks_rel#./}; done
if [ "${tasks_rel#/}" != "$tasks_rel" ]; then
  # Git reports the physical top-level path; resolve the file's directory the same way.
  top=$(git rev-parse --show-toplevel 2>/dev/null || true)
  dir=$(cd "$(dirname "$tasks_rel")" 2>/dev/null && pwd -P || true)
  if [ -n "$top" ] && [ "$dir" = "$top" ]; then tasks_rel=$(basename "$tasks_rel")
  elif [ -n "$top" ] && [ "${dir#"$top"/}" != "$dir" ]; then tasks_rel=${dir#"$top"/}/$(basename "$tasks_rel"); fi
fi
ntasks=$(jq '.tasks | length' "$TASKS")
[ "$ntasks" -gt 0 ] || die "no tasks"
# Expectations are decoded below with the other fixed metadata, so they must be
# nonempty lists of strings. NUL bytes would corrupt the NUL-delimited decoding.
bad_expect=$(jq -r '.tasks[] | select((.expect | type) != "array" or (.expect | length) == 0 or any(.expect[]; type != "string" or length == 0)) | .id' "$TASKS")
if [ -n "$bad_expect" ]; then
  die "task ${bad_expect%%$'\n'*}: expect must be a nonempty list of full-line regular expressions"
fi
if jq -e 'any(.tasks[]; ([.id, (.title // ""), .test] + .expect) | any(contains("\u0000")))' "$TASKS" >/dev/null; then
  die "invalid kit: task ids, titles, commands and expectations may not contain NUL bytes"
fi
# An expectation is one full-line regular expression. A newline would make grep
# treat its lines as alternatives, so "PASS\nFAIL" would accept a FAIL line.
if jq -e 'any(.tasks[].expect[]; contains("\n"))' "$TASKS" >/dev/null; then
  die "invalid kit: each expect must be a single-line regular expression (no newlines)"
fi
# Task metadata is fixed for a run. Decode once rather than spawning jq for
# every lookup during the quadratic acceptance check. NUL separators preserve
# multiline commands/titles without shell evaluation; indexed arrays work in
# macOS's Bash 3.2 as well as newer Bash versions.
task_ids=(); task_titles=(); task_tests=(); task_tiers=()
# Expectations are decoded here too, so judging never re-reads the kit file.
# Each task's expectation count is followed by its values; starts index the
# flat array. Judge order and full-line matching are unchanged.
task_expect_counts=(); task_expect_starts=(); task_expect_values=()
expect_total=0
while IFS= read -r -d '' value; do
  task_ids+=("$value")
  IFS= read -r -d '' value; task_titles+=("$value")
  IFS= read -r -d '' value; task_tests+=("$value")
  IFS= read -r -d '' value; task_tiers+=("$value")
  IFS= read -r -d '' value; expect_count=$value
  task_expect_counts+=("$expect_count"); task_expect_starts+=("$expect_total")
  expect_total=$((expect_total + expect_count))
  for ((k = 0; k < expect_count; k++)); do
    IFS= read -r -d '' value; task_expect_values+=("$value")
  done
done < <(jq -j '.tasks[] | (.id, .title, .test, .tier, (.expect | length | tostring), .expect[]) | (. // "" | tostring), "\u0000"' "$TASKS")
task() {
  case $2 in
    id) printf '%s\n' "${task_ids[$1]}";;
    title) printf '%s\n' "${task_titles[$1]}";;
    test) printf '%s\n' "${task_tests[$1]}";;
    tier) printf '%s\n' "${task_tiers[$1]}";;
  esac
}
for ((i = 0; i < ntasks; i++)); do
  id=$(task "$i" id)
  [[ $id =~ ^[a-zA-Z0-9_-]+$ ]] || die "task $i needs a simple, nonempty id"
  for ((k = 0; k < task_expect_counts[i]; k++)); do
    pattern=${task_expect_values[task_expect_starts[i] + k]}
    rc=0; grep -E -- "$pattern" /dev/null >/dev/null 2>&1 || rc=$?
    [ "$rc" -ne 2 ] || die "task $id: invalid expect regular expression: $pattern"
  done
done
if [ "$CHECK_ONLY" = 0 ]; then
  untracked=$(git ls-files --others --exclude-standard)
  [ -z "$untracked" ] || die "untracked files (ignore or commit before starting):
$untracked"
  [ -z "$(git status --porcelain)" ] || die "working tree is dirty"
  branch=$(git rev-parse --abbrev-ref HEAD)
  case $branch in main|master|HEAD) die "run on a branch, not $branch";; esac
  # Protected-path matching and restoration use paths relative to the repository top,
  # and the kit files are read from the current directory: start only at the top.
  [ -z "$(git rev-parse --show-prefix)" ] || die "run from the repository top level, not a subdirectory"
fi
state=.loop
git check-ignore -q "$state/x" || die "add .loop/ to .gitignore"
mkdir -p "$state"
log() { printf 'loop: %s\n' "$*" | tee -a "$state/loop.log" >&2; }
# Index flags make git ignore edits to a file: h = assume-unchanged, S = skip-worktree.
# Such a file vanishes from status, add, diff and checkout. Startup refuses flags
# the user set, because the clean-start gate could not see the tree. A coder run
# that sets flags is cleared before anything reads the tree (clear_index_flags).
# With both flags set, ls-files -v prints a lowercase s, so s must be matched too.
# Names stay NUL-delimited: a line-based listing split a name containing a newline,
# so its flag was missed. grep -z selects the flagged records ("h path", "s path",
# "S path"). Its ^ can also match after a newline inside a name, which can report a
# flag that is not set (a refusal or a failed attempt); it cannot miss a real flag.
refresh_index_flags() { git ls-files -v -z > "$state/index-flags"; }
index_flag_records() { # flagged records, NUL-delimited, to stdout
  local rc=0
  LC_ALL=C grep -azE '^[hsS] ' "$state/index-flags" || rc=$?
  [ "$rc" -le 1 ] || return 1 # 1 means that no entry is flagged
}
clear_index_flags() {
  local rec
  refresh_index_flags || return 1
  index_flag_records > "$state/index-flagged" || return 1
  while IFS= read -r -d '' rec; do
    log "clearing index flag set during the attempt on ${rec:2}"
    # One flag per call: git applies only the last mark option given in one invocation.
    git update-index --no-assume-unchanged -- "${rec:2}" || return 1
    git update-index --no-skip-worktree -- "${rec:2}" || return 1
  done < "$state/index-flagged"
}
# Ignored files: NUL-delimited, sorted paths git ignores (excluding the loop state),
# and the ones created since the attempt began. -z keeps names raw; without it git
# quotes non-ASCII and special names, and the quoted text cannot be removed.
# Removing the new ones on discard keeps a discarded attempt's artifacts from
# satisfying a later judge.
list_ignored() { git ls-files -z -o -i --exclude-standard -- ':(exclude).loop' | LC_ALL=C sort -z > "$1"; }
# zero_difference BEFORE AFTER OUT: entries of the sorted list AFTER that are absent
# from the sorted list BEFORE, NUL-delimited. comm is exact only when no name
# contains a newline, so that case takes the fast path; otherwise a bash merge
# (slower per entry, but exact) compares the NUL-delimited records.
zero_difference() {
  local b a have_b=0 have_a=0 LC_ALL=C
  if [ "$(cat "$1" "$2" | tr -cd '\n' | wc -c)" -eq 0 ]; then
    LC_ALL=C comm -13 <(tr '\0' '\n' < "$1") <(tr '\0' '\n' < "$2") | tr '\n' '\0' > "$3"
    return
  fi
  : > "$3"
  exec 3< "$1" 4< "$2" || return 1
  if IFS= read -r -d '' b <&3; then have_b=1; fi
  if IFS= read -r -d '' a <&4; then have_a=1; fi
  while [ "$have_a" = 1 ]; do
    if [ "$have_b" = 1 ] && [[ $b < $a ]]; then
      if IFS= read -r -d '' b <&3; then have_b=1; else have_b=0; fi
    elif [ "$have_b" = 1 ] && [ "$b" = "$a" ]; then
      if IFS= read -r -d '' a <&4; then have_a=1; else have_a=0; fi
    else
      printf '%s\0' "$a" >> "$3"
      if IFS= read -r -d '' a <&4; then have_a=1; else have_a=0; fi
    fi
  done
  exec 3<&- 4<&-
}
ignored_since_attempt() {
  list_ignored "$state/ignored.after" || return 1
  zero_difference "$state/ignored.before" "$state/ignored.after" "$state/ignored.new"
}
# Log helpers for NUL-delimited lists: count, and the first few names.
zero_count() { tr -cd '\0' < "$1" | wc -c | tr -d ' '; }
zero_names() { tr '\0' '\n' < "$1" | head -n 5 | tr '\n' ' '; }
if [ "$CHECK_ONLY" = 0 ]; then
  refresh_index_flags || die "could not read the git index"
  index_flag_records > "$state/index-flagged" || die "could not read the git index"
  [ ! -s "$state/index-flagged" ] || die "index flags hide edits from git (assume-unchanged or skip-worktree); clear them first:
$(tr '\0' '\n' < "$state/index-flagged")"
fi

# All judge commands (including diagnostic probes) are bounded. Keep stdout
# and stderr distinct: only stdout can satisfy an expectation.
run_judge_command() {
  local label=$1 command=$2 rc=0
  "$TIMEOUT" -k "$KILL_GRACE" "$JUDGE_TIMEOUT" bash -c "$command" > "$state/$label.stdout" 2> "$state/$label.stderr" || rc=$?
  if [ "$rc" = 124 ]; then
    log "$label timed out after ${JUDGE_TIMEOUT}s: $command"
  elif [ "$rc" = 137 ]; then
    log "$label killed (exit 137; timeout ignored SIGTERM or SIGKILL): $command"
  elif [ "$rc" != 0 ]; then
    log "$label exited $rc: $command"
  fi
  return "$rc"
}
task_passes() {
  local idx=$1 k=0 start=${task_expect_starts[$1]} count=${task_expect_counts[$1]}
  run_judge_command "test.$idx" "$(task "$idx" test)" || return 1
  while [ "$k" -lt "$count" ]; do
    grep -qxE -- "${task_expect_values[$((start + k))]}" "$state/test.$idx.stdout" || return 1
    k=$((k + 1))
  done
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
# Check-only modes cannot restore or discard, so a judge command that changes
# the working tree fails the run. Snapshots use a temporary index in .loop/ so
# the user's staged state is not changed.
# A failed add must not yield a partial tree that looks unchanged. Snapshots run
# in command substitutions, where set -e is not inherited, so return explicitly.
tree_snapshot() {
  rm -f "$state/check.index"
  GIT_INDEX_FILE="$state/check.index" git add -A || return 1
  GIT_INDEX_FILE="$state/check.index" git write-tree || return 1
}
judge_changed_tree() { # $1 = tree snapshot taken before judging; returns 0 if changed or unknown
  local now
  if ! now=$(tree_snapshot); then log "could not snapshot the working tree"; return 0; fi
  [ "$now" != "$1" ] || return 1
  log "judge commands modified the tree"
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
  before_tree=$(tree_snapshot)
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
  if judge_changed_tree "$before_tree"; then bad=1; fi
  exit "$bad"
fi
if [ "$CHECK_ONLY" = 1 ]; then
  before_tree=$(tree_snapshot)
  bad=0
  for ((i = 0; i < ntasks; i++)); do
    if judge "$i"; then r=pass; else r=FAIL; bad=1; fi
    printf '%-5s %s  %s\n' "$r" "$(task "$i" id)" "$(task "$i" title)"
  done
  if judge_changed_tree "$before_tree"; then bad=1; fi
  exit "$bad"
fi

revert_protected() {
  local f
  # NUL-delimited, with renames disabled: git quotes unusual names in line output,
  # and a rename hides the old path, which would then escape restoration.
  # Output goes to a file so a failing git command is seen, not hidden by a
  # process substitution. The pathspec is literal: a name such as a*b must not
  # match and restore other files.
  { git diff -z --no-renames --name-only HEAD && git ls-files -z --others --exclude-standard; } > "$state/paths" ||
    die "could not list changed paths"
  while IFS= read -r -d '' f; do
    [ -n "$f" ] || continue
    if grep -qE -- "$PROTECTED" <<< "$f" || [ "$f" = "$tasks_rel" ]; then
      if git cat-file -e "HEAD:$f" 2>/dev/null; then git checkout -q HEAD -- ":(literal)$f"; else rm -f -- "$f"; fi
    fi
  done < "$state/paths"
  # Ignored files are not in the listing above. Remove the protected ones this
  # attempt created, so the judge cannot pass on a file the commit does not contain.
  ignored_since_attempt || die "could not list ignored files"
  while IFS= read -r -d '' f; do
    if grep -qE -- "$PROTECTED" <<< "$f" || [ "$f" = "$tasks_rel" ]; then
      log "removing protected ignored file created by the attempt: $f"; rm -f -- "$f"
    fi
  done < "$state/ignored.new"
  # The loop's state directory must stay ignored, or later git add/clean would
  # stage its logs or delete them. Restore the ignore file if a coder broke it.
  if ! git check-ignore -q "$state/x"; then
    log "restoring .gitignore: $state/ must stay ignored"
    if git cat-file -e "HEAD:.gitignore" 2>/dev/null; then git checkout -q HEAD -- .gitignore; else rm -f -- .gitignore; fi
  fi
  # Restoring .gitignore may not be enough: a rule elsewhere (such as .git/info/exclude)
  # can still hide the state directory. Stop before anything is judged or committed.
  git check-ignore -q "$state/x" || die "$state/ is still not ignored after restoring .gitignore (check .git/info/exclude); stopping"
}
# Restoration happens before the snapshot, so a protected write that lands in
# between (a surviving descendant) would be judged and committed. Refuse instead.
protected_in_tree() { # $1 = tree; returns 0 if it changes a protected path relative to HEAD
  local f
  # If git cannot list the tree, refuse: an unlisted protected change must not pass.
  git diff-tree -r -z --no-renames --name-only HEAD "$1" > "$state/tree-paths" ||
    { log "could not list the judged tree; refusing"; return 0; }
  while IFS= read -r -d '' f; do
    if grep -qE -- "$PROTECTED" <<< "$f" || [ "$f" = "$tasks_rel" ]; then
      log "protected path changed before judging: $f"; return 0
    fi
  done < "$state/tree-paths"
  return 1
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
  prev=$(cat "$state/attempts.$id" 2>/dev/null || echo 0)
  # Coder-writable state is read as a plain count only: never evaluated as arithmetic.
  case $prev in ''|*[!0-9]*) die "$state/attempts.$id must hold a count, not: $prev";; esac
  n=$((10#$prev + 1))
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
  list_ignored "$state/ignored.before" || die "could not list ignored files"
  rc=0
  TASK_ID=$id ATTEMPT=$n "$TIMEOUT" -k "$KILL_GRACE" "$ITER_SECONDS" bash -c "$cmd" < "$state/prompt.md" > "$state/coder.$id.$n.log" 2>&1 || rc=$?
  [ "$rc" = 124 ] && log "coder timed out after ${ITER_SECONDS}s"
  [ "$rc" = 137 ] && log "coder killed (exit 137; timeout ignored SIGTERM or SIGKILL) after ${ITER_SECONDS}s limit"
  clear_index_flags || die "could not clear index flags"
  revert_protected
  ok=1
  # Timeouts fail attempts (SKILL.md): partial output from a killed coder is never judged or committed.
  if [ "$rc" = 124 ] || [ "$rc" = 137 ]; then ok=0; fi
  if [ -n "$FORMAT_CMD" ]; then run_judge_command format "$FORMAT_CMD" || ok=0; fi
  revert_protected # Formatting must not change protected paths either.
  git add -A
  judged_tree=$(git write-tree)
  if protected_in_tree "$judged_tree"; then ok=0; fi
  if [ "$ok" = 1 ]; then judge "$idx" || ok=0; fi
  # The formatter and judge commands can set index flags, which hide their edits from
  # the snapshot below. Any flag set since the coder fails the attempt; then clear them.
  refresh_index_flags || die "could not read the git index"
  index_flag_records > "$state/index-flagged" || die "could not read the git index"
  if [ -s "$state/index-flagged" ]; then log "index flags set during the attempt; attempt fails"; ok=0; fi
  clear_index_flags || die "could not clear index flags"
  git add -A
  if [ "$(git write-tree)" != "$judged_tree" ]; then
    log "judge commands modified the tree"
    ok=0
  fi
  # A pass that leaves the tree unchanged has nothing to commit (for example, a flaky
  # test). It fails the attempt rather than stopping the run on git's error.
  if [ "$ok" = 1 ] && [ "$judged_tree" = "$(git rev-parse HEAD^{tree})" ]; then
    log "judge passed with no change to commit; attempt fails"
    ok=0
  fi
  if [ "$ok" = 1 ]; then
    commit_attempt "loop: $id passes (attempt $n)" "$judged_tree"
    rm -f "$state/last.$id.diff"
    log "$id passed"
    # Not committed and not removed: they stay in the worktree and can affect later
    # judging. Logged so the gap is visible; the policy for them is an open decision.
    ignored_since_attempt || die "could not list ignored files"
    if [ -s "$state/ignored.new" ]; then
      log "warning: $(zero_count "$state/ignored.new") ignored file(s) created by this attempt are not committed: $(zero_names "$state/ignored.new")"
    fi
  else
    { git diff HEAD; git ls-files --others --exclude-standard | sed 's/^/new file: /'; } > "$state/last.$id.diff" || true
    # Keep only added note lines outside the committed tree before discarding. Only
    # hunk bodies count: file headers (such as +++) are skipped, but a note that begins with ++ is kept.
    git diff --no-ext-diff --unified=0 HEAD -- PROGRESS.md |
      awk '/^@@/ {hunk = 1; next} hunk && /^\+/ {print substr($0, 2)}' >> "$state/notes.$id"
    # The clean-start gate establishes that these are attempt-owned changes.
    # Discard the tree changes; saved notes and coder output remain in .loop/.
    git reset -q --hard HEAD
    git clean -qfd
    # clean -fd leaves ignored files. Remove those this attempt created (never
    # pre-existing caches, never .loop/), so a discarded artifact cannot satisfy a later judge.
    ignored_since_attempt || die "could not list ignored files"
    if [ -s "$state/ignored.new" ]; then
      log "removing $(zero_count "$state/ignored.new") ignored file(s) created by failed attempt $n: $(zero_names "$state/ignored.new")"
      while IFS= read -r -d '' f; do rm -f -- "$f"; done < "$state/ignored.new"
    fi
    log "$id failed attempt $n"
    if [ "$n" -ge "$MAX_ATTEMPTS" ]; then
      printf '%s failed %s attempts; see .loop/coder.%s.*.log\n' "$id" "$n" "$id" > STOP
      log "STOP — $id"; exit 2
    fi
  fi
done
log "iteration cap ($MAX_ITER) reached"; exit 3
