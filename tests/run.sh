#!/usr/bin/env bash
# Self-test for scripts/loop.sh. Needs bash, git, jq, perl and Go.
# Runs a toy kit against a scripted fake coder that cheats in several ways,
# and checks the loop catches each one. No model, network or key needed.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
loop=$here/../scripts/loop.sh
coder=$here/fakecoder.sh
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fails=0
check() { if [ "$2" = "$3" ]; then echo "ok    $1"; else echo "FAIL  $1: got '$2', want '$3'"; fails=1; fi; }

fresh() {
  rm -rf "$work/r"; cp -R "$here/toy-kit" "$work/r"; mkdir -p "$work/r/scripts"; cp "$loop" "$work/r/scripts/"
  cd "$work/r" && git init -q && git add -A && git -c user.name=t -c user.email=t@t commit -qm kit && git checkout -qb loop
}
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
export CHEAP_CMD="$coder cheap" STRONG_CMD="$coder strong" STRONGEST_CMD="$coder strongest"

fresh; ./scripts/loop.sh --check >/dev/null; check "stubs fail --check" $? 1
cp -R "$here/toy-ref/." .; ./scripts/loop.sh --check >/dev/null; check "reference passes --check" $? 0
git checkout -q -- . ; git clean -qfd

fresh; SCHEDULE="T1:1=cheat-init T1:2=cheat-newtest T1:3=cheat-edit T2:1=wrong T4:1=cheat-testdata" ./scripts/loop.sh >/dev/null 2>&1
check "cheats rejected, honest work committed" $? 0
check "no cheat file survives" "$(ls slug/zz_* 2>/dev/null | wc -l | tr -d ' ')" 0
changed=0; for f in $(cd "$here/toy-kit" && find . -name '*_test.go'); do cmp -s "$f" "$here/toy-kit/$f" || changed=1; done
check "tests unchanged" "$changed" 0
go test ./... -count=1 >/dev/null 2>&1; check "tree really passes" $? 0
check "T1 committed on attempt 4" "$(git log --format=%s | grep -c 'T1 passes (attempt 4)')" 1

fresh; SCHEDULE="T1:1=wrong T1:2=wrong T1:3=wrong T1:4=wrong" ./scripts/loop.sh >/dev/null 2>&1
check "STOP after max attempts" $? 2
check "STOP names the task" "$(cut -d' ' -f1 STOP)" T1

fresh; ITER_SECONDS=2 MAX_ITER=1 SCHEDULE="T1:1=sleep" ./scripts/loop.sh >/dev/null 2>&1
check "iteration cap" $? 3

fresh; echo x > dirt; ./scripts/loop.sh >/dev/null 2>&1; check "refuses dirty tree" $? 1

exit $fails
