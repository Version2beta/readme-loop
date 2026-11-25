#!/usr/bin/env bash
# Real-loop regression tests. No models/network. Requires the loop's existing
# bash/git/jq/coreutils dependencies, not Go, pytest or Elixir.
# Each case is also run against a deliberately regressed disposable loop copy.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
loop=$here/loop.sh
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export GIT_AUTHOR_NAME=fixture GIT_AUTHOR_EMAIL=fixture@example.invalid
export GIT_COMMITTER_NAME=fixture GIT_COMMITTER_EMAIL=fixture@example.invalid
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export MAX_ITER=8 MAX_ATTEMPTS=3 ITER_SECONDS=5 JUDGE_TIMEOUT=1

fail() { echo "ASSERTION FAILED: $*" >&2; exit 1; }
equal() { [ "$1" = "$2" ] || fail "$3: got [$1], expected [$2]"; }
contains() { grep -qF -- "$2" "$1" || fail "$1 lacks [$2]"; }
fixture() {
  mkdir -p "$work/repo/scripts"
  cd "$work/repo"
  cp "$loop" scripts/loop.sh
  printf '.loop/\nignored/\n' > .gitignore
  printf 'stub\n' > code
  printf 'fixture prompt\n' > PROMPT.md
  printf 'fixture spec\n' > SPEC.md
  : > PROGRESS.md
  cat > verify.sh <<'SH'
#!/usr/bin/env bash
case "$(tr -d ' ' < code)" in
  good) printf 'PASS T1\n';;
  substring) printf 'prefix PASS T1 suffix\n';;
  stderr) printf 'PASS T1\n' >&2;;
  nonzero) printf 'PASS T1\n'; exit 1;;
  hang) sleep 10; printf 'PASS T1\n';;
  *) exit 1;;
esac
SH
  cat > fake.sh <<'SH'
#!/usr/bin/env bash
set -eu
cat >/dev/null
case ${FAKE_MODE:-good} in
  good) printf 'good\n' > code; mkdir -p new; printf 'legitimate new file\n' > new/file;;
  formatted) printf ' g o o d \n' > code;;
  protected) printf "printf 'PASS T1\\n'\n" > verify.sh; printf 'cheat\n' > protected.new;;
  protected-good) printf "exit 1\n" > verify.sh; printf 'good\n' > code;;
  escalate) [ "$1" != strongest ] || printf 'good\n' > code;;
  regression) printf 'good\n' > code; printf 'broken\n' > earlier;;
  *) printf '%s\n' "$FAKE_MODE" > code;;
esac
printf 'attempt notes\n' >> PROGRESS.md
SH
  cat > tasks.json <<'JSON'
{
  "format": "tr -d ' ' < code > .loop/formatted && mv .loop/formatted code",
  "format_check": "! grep -q ' ' code",
  "check": "git add -A && git write-tree > .loop/judged-tree",
  "protected": ["^verify\\.sh$", "^protected\\."],
  "tasks": [{"id":"T1", "title":"fixture", "test":"bash verify.sh", "expect":["PASS T1"], "tier":"normal"}]
}
JSON
  git init -q
  git config core.excludesFile /dev/null
  git checkout -qb fixture
  git add -A
  git commit -qm fixture
  export CHEAP_CMD='bash fake.sh cheap' STRONG_CMD='bash fake.sh strong' STRONGEST_CMD='bash fake.sh strongest'
}
config() {
  jq "$1" tasks.json > "$work/tasks.json"
  mv "$work/tasks.json" tasks.json
  git add -A && git commit -qm configuration
}
run() {
  rc=0
  bash scripts/loop.sh "$@" > "$work/output" 2>&1 || rc=$?
}
unchanged() { equal "$(git rev-list --count HEAD)" "$before" 'no attempt committed'; }
case_run() {
  fixture
  case $1 in
    good)
      run; equal "$rc" 0 'good attempt succeeds'
      contains <(git log -1 --format=%B) 'Coder-Command: bash fake.sh cheap'
      contains .loop/loop.log 'Coder-Command: bash fake.sh cheap'
      equal "$(git status --porcelain)" '' 'clean after commit'
      git ls-files --error-unmatch new/file >/dev/null
      ;;
    formatted)
      FAKE_MODE=formatted run; equal "$rc" 0 'formatter fixes before judging'
      equal "$(git show HEAD:code)" good 'committed formatted code'
      equal "$(git rev-parse HEAD^{tree})" "$(<.loop/judged-tree)" 'committed tree equals entire judged tree'
      equal "$(git status --porcelain)" '' 'clean after formatted commit'
      ;;
    search-count)
      config '.tasks = [range(0; 5) | {id:("T" + tostring), title:"search", test:("echo " + tostring + " >> .loop/search-runs; " + (if . < 4 then "echo PASS" else "exit 1" end)), expect:["PASS"], tier:"normal"}]'
      cat > fake.sh <<'SH'
#!/usr/bin/env bash
cat >/dev/null
cp .loop/search-runs .loop/search-before-coder
SH
      git add fake.sh && git commit -qm 'count search before coder'
      MAX_ITER=1 run; equal "$rc" 3 'one iteration stops at cap'
      equal "$(<.loop/search-before-coder)" "$(printf '0\n1\n2\n3\n4')" 'search runs each task exactly once in order'
      ;;
    notes|notes-cross-task)
      if [ "$1" = notes-cross-task ]; then
        config '.format = "test \"$(cat code)\" = good" | .tasks = [{id:"T0", title:"move on", test:"test -f .loop/move-on && echo DONE", expect:["DONE"], tier:"normal"}] + .tasks'
        saved=T0
      else saved=T1; fi
      cat > fake.sh <<'SH'
#!/usr/bin/env bash
cat > .loop/received-prompt
if [ ! -f .loop/move-on ]; then
  printf 'remember failed approach\n' >> PROGRESS.md
  touch .loop/move-on
else
  printf 'good\n' > code
fi
SH
      git add fake.sh && git commit -qm 'notes fake coder'
      before=$(git rev-list --count HEAD)
      MAX_ITER=1 run; equal "$rc" 3 'failed attempt stops at iteration cap'
      unchanged
      equal "$(<PROGRESS.md)" '' 'failed notes not left in tree'
      contains ".loop/notes.$saved" 'remember failed approach'
      MAX_ITER=1 run; equal "$rc" 3 'next attempt completes within one iteration'
      contains .loop/received-prompt 'Notes from discarded attempts'
      contains <(awk '/### Notes from discarded attempts/ {notes=1; next} /### Your previous attempt/ {notes=0} notes' .loop/received-prompt) 'remember failed approach'
      equal "$(git rev-list --count HEAD)" "$((before + 1))" 'only judged success committed'
      equal "$(git show HEAD:PROGRESS.md)" '' 'discarded notes never committed'
      if [ "$1" = notes-cross-task ]; then
        contains .loop/received-prompt '## Task T1:'
      fi
      ;;
    judge-writes)
      config '.check = "printf changed > tracked"'
      printf 'original\n' > tracked
      git add tracked && git commit -qm 'tracked check target'
      before=$(git rev-list --count HEAD)
      run; equal "$rc" 2 'writing check fails attempt'
      contains .loop/loop.log 'judge commands modified the tree'
      unchanged
      equal "$(<tracked)" original 'judge mutation discarded'
      ;;
    formatter-protected)
      config '.format = "printf formatter-edit > SPEC.md"'
      run; equal "$rc" 0 'formatter protected edits restored before judge'
      equal "$(git show HEAD:SPEC.md)" 'fixture spec' 'formatter cannot commit protected edit'
      equal "$(git status --porcelain)" '' 'formatter protected case clean'
      ;;
    protected)
      before=$(git rev-list --count HEAD)
      FAKE_MODE=protected run; equal "$rc" 2 'protected edit cannot make task pass'
      unchanged
      equal "$(git show HEAD:verify.sh)" "$(<verify.sh)" 'protected test restored'
      [ ! -e protected.new ] || fail 'new protected path survives'
      # A protected edit must not prevent otherwise correct work passing.
      rm STOP; rm -rf .loop
      FAKE_MODE=protected-good run; equal "$rc" 0 'honest code with test edit passes on merits'
      ;;
    substring|stderr|nonzero)
      before=$(git rev-list --count HEAD)
      FAKE_MODE=$1 run; equal "$rc" 2 "$1 spoof rejected"
      unchanged
      contains .loop/loop.log 'T1 failed attempt 3'
      ;;
    hang)
      before=$(git rev-list --count HEAD)
      # An outer deadline makes a missing inner timeout fail, not hang tests.
      FAKE_MODE=hang bounded_run
      equal "$rc" 2 'hanging test counted as failure, not outer timeout'
      contains .loop/loop.log 'test.0 timed out after 1s: bash verify.sh'
      contains .loop/loop.log 'T1 failed attempt 3'
      unchanged
      ;;
    empty-command)
      before=$(git rev-list --count HEAD)
      for name in CHEAP_CMD STRONG_CMD STRONGEST_CMD; do
        run_empty "$name"
        equal "$rc" 1 "$name refused"
        contains "$work/output" "$name is empty"
        [ ! -d .loop ] || fail 'coder state created for invalid command'
      done
      unchanged
      ;;
    empty-expect|missing-expect)
      if [ "$1" = empty-expect ]; then config '.tasks[0].expect = []'
      else config 'del(.tasks[0].expect)'; fi
      run; equal "$rc" 1 'invalid expectations refuse startup'
      contains "$work/output" 'task T1: expect'
      [ ! -d .loop ] || fail 'coder ran with invalid expectations'
      ;;
    legacy)
      config '.pass_marker = "PASS {name}"'
      run; equal "$rc" 1 'legacy field refuses startup'
      contains "$work/output" 'pass_marker is obsolete; use tasks[].expect'
      ;;
    untracked)
      mkdir -p .wtha ignored; printf 'tool output\n' > .wtha/report; : > ignored/cache
      run; equal "$rc" 1 'untracked files refuse startup'
      contains "$work/output" '.wtha/report'
      if grep -qF ignored/cache "$work/output"; then fail 'ignored output listed'; fi
      [ ! -d .loop ] || fail 'coder state created with untracked output'
      ;;
    defaults)
      mkdir bin
      cat > bin/pi <<'SH'
#!/usr/bin/env bash
case "$*" in
  '--provider anthropic --model claude-haiku-5-5 --thinking high --print --no-session') role=cheap;;
  '--provider openai-codex --model gpt-6.1-sol --thinking high --print --no-session') role=strong;;
  '--provider openai-codex --model gpt-6.1-sol --thinking max --print --no-session') role=strongest;;
  *) echo "unexpected Pi command: $*" >&2; exit 99;;
esac
printf '%s\n' "$*" >> .loop/pi-args
bash fake.sh "$role"
SH
      chmod +x bin/pi
      git add bin/pi && git commit -qm 'fake Pi executable, never a model'
      rc=0
      PATH="$PWD/bin:$PATH" FAKE_MODE=escalate env -u CHEAP_CMD -u STRONG_CMD -u STRONGEST_CMD \
        bash scripts/loop.sh > "$work/output" 2>&1 || rc=$?
      equal "$rc" 0 'all pinned defaults invoke fake Pi with exact flags'
      equal "$(wc -l < .loop/pi-args | tr -d ' ')" 3 'three default invocations'
      contains <(git log -1 --format=%B) 'Coder-Command: pi --provider openai-codex --model gpt-6.1-sol --thinking max --print --no-session'
      ;;
    hard)
      config '.tasks[0].tier = "hard"'
      run; equal "$rc" 0 'hard task succeeds'
      contains .loop/loop.log 'attempt 1/3  Coder-Command: bash fake.sh strong'
      ;;
    escalation)
      FAKE_MODE=escalate run; equal "$rc" 0 'last attempt succeeds'
      mapfile_compat
      equal "${commands[0]}" 'bash fake.sh cheap' 'first command'
      equal "${commands[1]}" 'bash fake.sh strong' 'retry command'
      equal "${commands[2]}" 'bash fake.sh strongest' 'last command'
      contains <(git log -1 --format=%B) 'Coder-Command: bash fake.sh strongest'
      ;;
    check-format)
      printf ' g o o d \n' > code
      run --check; equal "$rc" 1 '--check rejects bad formatting'
      contains .loop/loop.log 'format_check exited 1'
      equal "$(<code)" ' g o o d ' '--check does not format'
      ;;
    check-command)
      printf 'good\n' > code
      config '.check = "exit 1"'
      run --check; equal "$rc" 1 '--check runs kit check'
      contains .loop/loop.log 'check exited 1'
      ;;
    earlier)
      printf 'ok\n' > earlier
      config '.tasks = [{id:"T0", title:"earlier", test:"test \"$(cat earlier)\" = ok && echo EARLIER", expect:["EARLIER"], tier:"normal"}] + .tasks'
      before=$(git rev-list --count HEAD)
      FAKE_MODE=regression run; equal "$rc" 2 'earlier test regression rejected'
      unchanged
      ;;
    timeout-format|timeout-format-check|timeout-check)
      field=${1#timeout-}; field=${field//-/_}
      config ".$field = \"sleep 10\""
      before=$(git rev-list --count HEAD)
      FAKE_MODE=good bounded_run
      equal "$rc" 2 "$field timeout fails attempts"
      contains .loop/loop.log "$field timed out after 1s: sleep 10"
      unchanged
      ;;
    check-once)
      printf 'good\n' > code
      config '.tasks = [{id:"T0", title:"counted", test:"echo run >> .loop/t0-runs && echo EARLIER", expect:["EARLIER"], tier:"normal"}] + .tasks'
      run --check-once; equal "$rc" 0 '--check-once passes a good tree'
      equal "$(wc -l < .loop/t0-runs | tr -d ' ')" 1 '--check-once runs each task once'
      contains "$work/output" 'pass  format_check'
      contains "$work/output" 'pass  T0  counted'
      contains "$work/output" 'pass  T1  fixture'
      contains "$work/output" 'pass  check'
      printf 'bad\n' > code
      run --check-once; equal "$rc" 1 '--check-once fails a failing task'
      contains "$work/output" 'FAIL  T1  fixture'
      ;;
    check-once-metadata)
      config '.tasks[0].title = "multi\nline $(touch injected)" | .tasks[0].test = "printf \"PASS T1\\n\"\nprintf \"SECOND\\n\""'
      run --check-once; equal "$rc" 0 'multiline metadata passes'
      equal "$(<.loop/test.0.stdout)" "$(printf 'PASS T1\nSECOND')" 'multiline command preserved'
      contains "$work/output" 'line $(touch injected)'
      [ ! -e injected ] || fail 'metadata was evaluated as shell code'
      ;;
    check-once-select)
      printf 'good\n' > code
      config '.tasks = [{id:"T0", title:"broken", test:"exit 1", expect:["NEVER"], tier:"normal"}] + .tasks'
      run --check-once T1; equal "$rc" 0 '--check-once runs only selected tasks'
      if grep -q 'T0' "$work/output"; then fail 'unselected task T0 was judged'; fi
      run --check-once nosuch; equal "$rc" 1 'unknown task id refused'
      contains "$work/output" 'no task nosuch'
      ;;
    check-once-gates)
      printf ' g o o d \n' > code
      run --check-once T1; equal "$rc" 1 '--check-once runs format_check'
      contains "$work/output" 'FAIL  format_check'
      equal "$(<code)" ' g o o d ' '--check-once does not format'
      printf 'good\n' > code
      config '.check = "exit 1"'
      run --check-once T1; equal "$rc" 1 '--check-once runs kit check'
      contains "$work/output" 'FAIL  check'
      ;;
    *) fail "unknown case $1";;
  esac
}
run_empty() { rc=0; env "$1=" bash scripts/loop.sh > "$work/output" 2>&1 || rc=$?; }
bounded_run() { rc=0; "$outer_timeout" 15 bash scripts/loop.sh > "$work/output" 2>&1 || rc=$?; }
mapfile_compat() {
  commands=()
  while IFS= read -r line; do commands+=("${line#*Coder-Command: }"); done < <(grep 'Coder-Command:' .loop/loop.log)
  equal "${#commands[@]}" 3 'exact attempt log count'
}
outer_timeout=$(command -v timeout || command -v gtimeout)
if [ "${1:-}" = --case ]; then
  loop=$3
  case_run "$2"
  exit 0
fi

# Regress only a disposable copy, never the installed loop. Literal replacement
# guards prevent a stale mutation from silently becoming a no-op.
mutate() {
  local old=$1 new=$2
  [[ $source == *"$old"* ]] || fail "mutation anchor absent: $old"
  source=${source/"$old"/"$new"}
}
cases=(search-count notes notes-cross-task judge-writes formatter-protected good formatted protected substring stderr nonzero hang empty-command empty-expect missing-expect legacy untracked defaults hard escalation check-format check-command earlier timeout-format timeout-format-check timeout-check check-once check-once-metadata check-once-select check-once-gates)
fails=0
for name in "${cases[@]}"; do
  if bash "$0" --case "$name" "$loop" > "$work/case.log" 2>&1; then
    printf 'PASS  %s\n' "$name"
  else
    printf 'FAIL  %s\n' "$name"; cat "$work/case.log"; fails=$((fails + 1))
  fi
  source=$(<"$loop")
  case $name in
    search-count) mutate 'do task_passes "$i" || { echo "$i"; return; }; done' 'do judge "$i" || { echo "$i"; return; }; done';;
    notes|notes-cross-task) mutate 'cat "$notes"' ': # discard saved prompt notes';;
    judge-writes) mutate 'if [ "$(git write-tree)" != "$judged_tree" ]; then' 'if false; then'
      mutate 'commit_attempt "loop: $id passes (attempt $n)" "$judged_tree"' 'commit_attempt "loop: $id passes (attempt $n)" "$(git write-tree)"'
      ;;
    formatter-protected) mutate 'revert_protected # Formatting must not change protected paths either.' ': # formatter protected edits survive';;
    good) mutate 'Coder-Command: $cmd"' 'model: $cmd"';;
    formatted)
      mutate 'if [ -n "$FORMAT_CMD" ]; then run_judge_command format "$FORMAT_CMD" || ok=0; fi' ':'
      mutate 'commit_attempt "loop: $id passes (attempt $n)"' 'bash -c "$FORMAT_CMD"; commit_attempt "loop: $id passes (attempt $n)"'
      ;;
    protected)
      mutate '  revert_protected' '  : # no protected revert'
      mutate '  revert_protected # Formatting must not change protected paths either.' '  : # no post-format protected revert'
      ;;
    substring) mutate 'grep -qxE' 'grep -qE';;
    stderr)
      mutate 'local label=$1 command=$2 rc=0' 'local label=$1 command=$2 rc=0; : > "$state/$label.stderr"'
      mutate '2> "$state/$label.stderr"' '2>&1'
      ;;
    nonzero) mutate '"$(task "$idx" test)" || return 1' '"$(task "$idx" test)" || true';;
    hang|timeout-*) mutate '"$TIMEOUT" "$JUDGE_TIMEOUT" bash -c "$command"' 'bash -c "$command"';;
    empty-command) mutate '[ -n "${!setting}" ] || die "$setting is empty"' ':';;
    empty-expect|missing-expect)
      mutate 'die "task $id: expect must be a nonempty list of full-line regular expressions"' ':'
      mutate '.expect[]"' '.expect[]?"'
      ;;
    legacy) mutate 'die "pass_marker is obsolete; use tasks[].expect full-line regular expressions"' ':';;
    untracked)
      mutate '[ -z "$untracked" ] || die "untracked files (ignore or commit before starting):
$untracked"' ':'
      # Old behavior refuses dirty files, but neither identifies nor lists them.
      ;;
    defaults) mutate '--thinking max --print --no-session' '--thinking high --print --no-session';;
    hard) mutate '[ "$tier" = hard ]' '[ "$tier" = never ]';;
    escalation) mutate 'then cmd=$STRONGEST_CMD' 'then cmd=$STRONG_CMD';;
    check-format) mutate 'if judge "$i"; then r=pass' 'if task_passes "$i"; then r=pass';;
    check-command) mutate 'if [ -n "$CHECK_CMD" ]; then run_judge_command check "$CHECK_CMD" || return 1; fi' ':';;
    earlier) mutate 'for ((j = 0; j < idx; j++)); do task_passes "$j" || return 1; done' ':';;
    check-once) mutate '    if task_passes "$i"; then r=pass; else r=FAIL; bad=1; fi
    printf' '    if judge "$i"; then r=pass; else r=FAIL; bad=1; fi
    printf';;
    check-once-metadata) mutate 'task_tests+=("$value")' 'task_tests+=("exit 1")';;
    check-once-select) mutate 'if [ "$#" = 0 ]; then' 'if true; then';;
    check-once-gates)
      mutate '    if run_judge_command format_check "$FORMAT_CHECK_CMD"; then r=pass' '    if true; then r=pass'
      mutate '    if run_judge_command check "$CHECK_CMD"; then r=pass' '    if true; then r=pass'
      ;;
  esac
  printf '%s\n' "$source" > "$work/regressed.sh"
  if bash "$0" --case "$name" "$work/regressed.sh" > "$work/mutation.log" 2>&1; then
    printf 'FAIL  mutation survived: %s\n' "$name"; fails=$((fails + 1))
  else
    printf 'CAUGHT old-behavior regression: %s — ' "$name"
    grep -m1 'ASSERTION FAILED:' "$work/mutation.log" || { cat "$work/mutation.log"; fails=$((fails + 1)); }
  fi
done
[ "$fails" = 0 ] || { printf '%s checks failed\n' "$fails"; exit 1; }
printf 'All %s real-loop cases passed; all %s regressions caught. No model calls.\n' "${#cases[@]}" "${#cases[@]}"
