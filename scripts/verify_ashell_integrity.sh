#!/bin/sh
# verify_ashell_integrity.sh — quick E2E integrity checks inside a-Shell on device.
# Run after an Xcode build/install, from an a-Shell terminal prompt:
#   sh scripts/verify_ashell_integrity.sh
# or copy into Documents and: sh ~/Documents/verify_ashell_integrity.sh
#
# Exit 0 = all required checks passed; non-zero = at least one required check failed.
set -eu

PASS=0
FAIL=0
WARN=0
OUT="${TMPDIR:-/tmp}/ashell-integrity-$$"
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT HUP INT TERM

say() { printf '%s\n' "$*"; }
ok() { PASS=$((PASS + 1)); say "PASS  $*"; }
bad() { FAIL=$((FAIL + 1)); say "FAIL  $*"; }
warn() { WARN=$((WARN + 1)); say "WARN  $*"; }

say "=== a-Shell integrity $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="
say "pwd=$(pwd)"
say "HOME=${HOME:-}"
say "GROUP=${GROUP:-}"

# --- env ---
say ""
say "## env"
env >"$OUT/env.txt" 2>"$OUT/env.err" || true
if [ -s "$OUT/env.txt" ]; then
  ok "env produced output ($(wc -l <"$OUT/env.txt" | tr -d ' ') lines)"
else
  bad "env produced no output"
fi
for key in HOME PATH TERM COLUMNS LINES; do
  if env | grep -q "^${key}="; then
    ok "env has $key"
  else
    bad "env missing $key"
  fi
done

# --- help -l ---
say ""
say "## help -l"
if help -l >"$OUT/help.txt" 2>"$OUT/help.err"; then
  count=$(wc -l <"$OUT/help.txt" | tr -d ' ')
  if [ "$count" -gt 20 ]; then
    ok "help -l listed $count commands"
  else
    bad "help -l listed only $count commands (expected >20)"
  fi
  for cmd in config pkg curl open help; do
    if grep -qw "$cmd" "$OUT/help.txt"; then
      ok "help -l contains $cmd"
    else
      warn "help -l missing $cmd (may be target-specific)"
    fi
  done
  if grep -qw codex "$OUT/help.txt"; then
    ok "help -l contains codex (full app)"
  else
    warn "codex not listed (expected on mini / pre-iOS-26.2 / missing xcframework)"
  fi
else
  bad "help -l failed"
fi

# --- .relay.json ---
say ""
say "## .relay.json"
RELAY_CANDIDATES=""
for d in \
  "${HOME:-}/Documents" \
  "${HOME:-}" \
  "${GROUP:-}/Documents" \
  "${GROUP:-}/Library" \
  "${HOME:-}/Library"
do
  [ -n "$d" ] || continue
  if [ -f "$d/.relay.json" ]; then
    RELAY_CANDIDATES="$RELAY_CANDIDATES $d/.relay.json"
  fi
done
if [ -z "$RELAY_CANDIDATES" ]; then
  warn "no .relay.json found (default: relay disabled until first configure/on)"
else
  for f in $RELAY_CANDIDATES; do
    ok "found $f"
    if grep -q '"enabled"' "$f" && grep -q '"bind"' "$f" && grep -q '"port"' "$f"; then
      ok "$f has enabled/bind/port keys"
    else
      bad "$f missing required keys"
    fi
    if grep -q '"enabled"[[:space:]]*:[[:space:]]*true' "$f"; then
      warn "$f has enabled=true (autostart on next launch)"
    else
      ok "$f enabled is not true (safe default / stopped)"
    fi
    if grep -q '"bind"[[:space:]]*:[[:space:]]*"127.0.0.1"' "$f"; then
      ok "$f bind is loopback 127.0.0.1"
    elif grep -q '"bind"[[:space:]]*:[[:space:]]*"0.0.0.0"' "$f" || grep -q '"bind"[[:space:]]*:[[:space:]]*"::"' "$f"; then
      warn "$f bind is all-interfaces (LAN exposure if enabled)"
    else
      warn "$f bind value unexpected; inspect manually"
    fi
  done
fi
if command -v relay >/dev/null 2>&1 || help -l 2>/dev/null | grep -qw relay; then
  if relay status >"$OUT/relay-status.txt" 2>"$OUT/relay-status.err"; then
    ok "relay status ran"
    say "---- relay status ----"
    cat "$OUT/relay-status.txt"
    say "----------------------"
  else
    warn "relay status failed (command may need Documents cwd)"
  fi
else
  warn "relay command not available in this target"
fi

# --- pbcopy / pbpaste ---
say ""
say "## clipboard pbcopy/pbpaste"
MARKER="ashell-integrity-$$"
if command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then
  printf '%s' "$MARKER" | pbcopy
  got=$(pbpaste 2>/dev/null || true)
  if [ "$got" = "$MARKER" ]; then
    ok "pbcopy/pbpaste round-trip"
  else
    bad "pbcopy/pbpaste mismatch (got='$got')"
  fi
else
  warn "pbcopy/pbpaste not in PATH (check help -l / target)"
fi

# --- local ports ---
say ""
say "## local listeners (Wasm / Relay)"
WASM_PORT="${WasmServerPort:-8443}"
RELAY_PORT="${RelayServerPort:-8765}"
# Info.plist values are not exported; try common full/mini defaults.
for pair in "8443:wasm-full" "8334:wasm-mini" "8765:relay-full" "8766:relay-mini"; do
  port=${pair%%:*}
  label=${pair##*:}
  # Prefer curl against localhost TLS; do not fail the suite on cert expiry.
  if command -v curl >/dev/null 2>&1; then
    code=$(curl -k -s -o /dev/null -w '%{http_code}' --connect-timeout 2 "https://127.0.0.1:${port}/" 2>/dev/null || true)
    code=$(printf '%s' "$code" | tr -cd '0-9')
    [ -n "$code" ] || code=000
    case "$code" in
      000|0)
        if echo "$label" | grep -q wasm; then
          warn "no TLS response on 127.0.0.1:$port ($label) — server may be down or different port"
        else
          ok "no TLS acceptor on 127.0.0.1:$port ($label) — expected when relay is off"
        fi
        ;;
      *)
        ok "TLS acceptor on 127.0.0.1:$port ($label) HTTP=$code"
        ;;
    esac
  elif command -v nc >/dev/null 2>&1; then
    if nc -z 127.0.0.1 "$port" >/dev/null 2>&1; then
      ok "TCP open 127.0.0.1:$port ($label)"
    else
      if echo "$label" | grep -q wasm; then
        warn "TCP closed 127.0.0.1:$port ($label)"
      else
        ok "TCP closed 127.0.0.1:$port ($label) — relay likely off"
      fi
    fi
  else
    warn "neither curl nor nc available for port probe"
    break
  fi
done
say "(plist defaults: full Wasm=$WASM_PORT Relay=$RELAY_PORT; mini often 8334/8766)"

# --- summary ---
say ""
say "=== summary PASS=$PASS WARN=$WARN FAIL=$FAIL ==="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
