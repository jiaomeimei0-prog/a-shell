#!/bin/sh
# verify_command_catalogue_158.sh — nghiệm thu catalogue 158 lệnh trong a-Shell.
# Chạy trên thiết bị / Simulator sau Xcode install (full app):
#   sh scripts/verify_command_catalogue_158.sh
# (copy file vào Documents nếu cần)
set -eu

PASS=0
FAIL=0
MISS=0
OUT="${TMPDIR:-/tmp}/ashell-cmds-158-$$"
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT HUP INT TERM

say() { printf '%s\n' "$*"; }
ok() { PASS=$((PASS + 1)); }
bad() { FAIL=$((FAIL + 1)); say "FAIL  $*"; }
miss() { MISS=$((MISS + 1)); say "MISS  $*"; }

say "=== Catalogue 158 acceptance $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="

if ! help -l >"$OUT/help.txt" 2>"$OUT/help.err"; then
  bad "help -l failed"
  exit 1
fi
helplines=$(wc -l <"$OUT/help.txt" | tr -d ' ')
say "help -l lines: $helplines"

# Auto-generated from Resources/commandDictionary.plist (full) — do not hand-edit.
EXPECTED="alias apropos awk base64 basename bc blink calc cat cbc cd chdir chflags chmod cksum codex compare composite compress conjure convert cp curl curl-impersonate dash date dc diff dig dirname du echo ed egrep ein env export expr fd ffmpeg ffprobe fgrep find fzf gix grep gunzip gzip head host hx id identify ifconfig import jq jsc jsc_core kpsewhich less lessecho lex lg2 link ln ls lua luac magick magick-script make man mandoc mandocdb md5 mkdir mogrify montage more multimarkdown mv navi nc node npm npx nslookup open openrsync openurl pbcopy pbpaste perl perl5 pico ping ping6 printenv pwd python python3 python3.13 readlink realpath rg rlogin rm rmdir rsync ruff say scp sed setenv sftp sh sha1 sha256 sleep sort source ssh ssh-add ssh-agent ssh-keygen stat stream stty sum sw_vers tail tar task tee telnet touch tr true type unalias uname uncompress uniq unlink unrar unsetenv uptime vim wasm3 wasmkit wc whatis whoami whois wol xargs xcode-select xxd"

n_expect=0
for _ in $EXPECTED; do n_expect=$((n_expect + 1)); done
if [ "$n_expect" -ne 158 ]; then
  bad "embedded EXPECTED count is $n_expect (want 158)"
  exit 1
fi
say "expected catalogue size: $n_expect"

missing=""
for cmd in $EXPECTED; do
  if grep -qw "$cmd" "$OUT/help.txt"; then
    ok
  else
    miss "$cmd"
    missing="$missing $cmd"
  fi
done
say "listed OK: $PASS / $n_expect"

SMOKE="echo env date pwd uname whoami true ls cat head wc"
for cmd in $SMOKE; do
  if ! grep -qw "$cmd" "$OUT/help.txt"; then
    say "SKIP  smoke $cmd (not in help -l)"
    continue
  fi
  rm -f "$OUT/smoke.out"
  if [ "$cmd" = "true" ] && true; then
    say "SMOKE OK  true"
  elif [ "$cmd" = "echo" ] && echo ok >"$OUT/smoke.out" 2>&1; then
    say "SMOKE OK  echo"
  elif [ "$cmd" = "pwd" ] && pwd >"$OUT/smoke.out" 2>&1; then
    say "SMOKE OK  pwd"
  elif "$cmd" --help >"$OUT/smoke.out" 2>&1; then
    say "SMOKE OK  $cmd --help"
  elif "$cmd" -h >"$OUT/smoke.out" 2>&1; then
    say "SMOKE OK  $cmd -h"
  elif [ -s "$OUT/smoke.out" ]; then
    say "SMOKE OK  $cmd (output)"
  else
    # last resort: run with no args briefly for benign cmds
    case "$cmd" in
      env|date|uname|whoami|ls)
        if "$cmd" >"$OUT/smoke.out" 2>&1; then say "SMOKE OK  $cmd"; else bad "smoke $cmd"; fi
        ;;
      *)
        bad "smoke $cmd"
        ;;
    esac
  fi
done

say ""
say "=== summary listed_ok=$((n_expect - MISS)) miss=$MISS fail=$FAIL ==="
if [ -n "$missing" ]; then
  say "Missing:$missing"
fi
if [ "$FAIL" -gt 0 ] || [ "$MISS" -gt 0 ]; then
  exit 1
fi
say "ACCEPT: all 158 catalogue names present in help -l"
exit 0
