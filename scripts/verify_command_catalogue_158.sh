#!/bin/sh
# verify_command_catalogue_158.sh — nghiệm thu catalogue 158 lệnh trong a-Shell.
# Chạy trên thiết bị / Simulator sau Xcode install (full app, không phải mini):
#   sh ~/Documents/verify_command_catalogue_158.sh
# hoặc từ bản copy trong repo Files.
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

# 158 names from Resources/commandDictionary.plist (full) — byte-identical to holzschu tip.
EXPECTED="alias apropos awk base64 basename bc blink calc cat cbc cd chdir chflags chmod cksum codex compare composite compress conjure convert cp curl curl-impersonate dash date dc diff dig dirname du echo ed egrep ein env export expr fd ffmpeg ffprobe fgrep find fzf gix grep gunzip gzip head hexdump hx identify ifconfig jsc json_pp json_xs jump less lg2 link ln ls lua luac magick make man mandoc md5 mkdir more mv nano nc networksetup newgrp nice nl nohup nslookup od open openrsync openssl pbpaste pbcopy pdfdetach pdffonts pdfimages pdfinfo pdfseparate pdftocairo pdftoppm pdftotext pdfunite pico ping pkg_add pkg_delete pkg_info printenv printf ps pwd python3 python3.13 readlink reboot reset rg rm rmdir rsync say scp script sed seq setenv sftp sh sha1 sha224 sha256 sha384 sha512 sleep sort ssh ssh-add ssh-agent ssh-keygen ssh-keyscan stat stream stty sum tac tail tar tee test touch tr true tsort unalias uname uncompress unexpand uniq unlink unset unsetenv uptime vim vimtutor wc which whoami whois xargs xxd xz xzcat xzcmp xzdiff xzgrep xzless xzmore yes zcat zcmp zdiff zegrep zfgrep zforce zgrep zless zmore znew"

# Note: list above must stay in sync with commandDictionary.plist (158 entries).
n_expect=0
for _ in $EXPECTED; do n_expect=$((n_expect + 1)); done
if [ "$n_expect" -ne 158 ]; then
  bad "embedded EXPECTED count is $n_expect (want 158) — regenerate script"
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

# Safe smoke (non-interactive subset present in the 158)
SMOKE="echo env date pwd uname whoami true ls cat head wc"
for cmd in $SMOKE; do
  if ! grep -qw "$cmd" "$OUT/help.txt"; then
    say "SKIP  smoke $cmd (not in help -l)"
    continue
  fi
  rm -f "$OUT/smoke.out"
  if "$cmd" --help >"$OUT/smoke.out" 2>&1; then
    say "SMOKE OK  $cmd --help"
  elif "$cmd" -h >"$OUT/smoke.out" 2>&1; then
    say "SMOKE OK  $cmd -h"
  elif [ "$cmd" = "true" ] && true; then
    say "SMOKE OK  true"
  elif [ "$cmd" = "echo" ] && echo ok >"$OUT/smoke.out" 2>&1; then
    say "SMOKE OK  echo"
  elif [ "$cmd" = "pwd" ] && pwd >"$OUT/smoke.out" 2>&1; then
    say "SMOKE OK  pwd"
  elif [ -s "$OUT/smoke.out" ]; then
    say "SMOKE OK  $cmd (output)"
  else
    bad "smoke $cmd"
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
