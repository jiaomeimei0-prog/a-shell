#!/usr/bin/env bash
# Host-side assert: Relay defaults are off + loopback; disabled path skips NWListener.
# No iOS runtime required. Exit 0 = PASS with observed evidence; non-zero = FAIL.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RELAY_SWIFT="${ROOT}/a-Shell/Relay.swift"
FAIL=0

say() { printf '%s\n' "$*"; }
ok() { say "PASS: $*"; }
bad() { say "FAIL: $*"; FAIL=1; }

say "## assert_relay_defaults ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
say "file: $RELAY_SWIFT"

if [[ ! -f "$RELAY_SWIFT" ]]; then
  bad "Relay.swift missing"
  exit 1
fi

# --- default enabled=false ---
if rg -n 'var enabled = false' "$RELAY_SWIFT" >/tmp/relay-enabled.txt; then
  ok "default enabled=false"
  cat /tmp/relay-enabled.txt
else
  bad "expected 'var enabled = false' in RelayConfiguration"
fi

# --- default bind=127.0.0.1 ---
if rg -n 'var bind = "127\.0\.0\.1"' "$RELAY_SWIFT" >/tmp/relay-bind.txt; then
  ok 'default bind="127.0.0.1"'
  cat /tmp/relay-bind.txt
else
  bad 'expected var bind = "127.0.0.1"'
fi

# --- autostart gated on enabled ---
if rg -n 'if configuration\.enabled \{ try self\.start\(configuration\) \}' "$RELAY_SWIFT" >/tmp/relay-gate.txt; then
  ok "autostart only calls start() when configuration.enabled"
  cat /tmp/relay-gate.txt
else
  bad "missing enabled-gated start() call"
fi

# --- NWListener only inside start path (not constructed when disabled) ---
# Count NWListener( sites; require they sit after a start()/listener assignment path,
# and that disabled path never creates a listener without going through start().
listener_hits=$(rg -n 'NWListener\(' "$RELAY_SWIFT" || true)
say "NWListener( sites:"
say "${listener_hits:-"(none)"}"
if [[ -z "$listener_hits" ]]; then
  bad "expected NWListener( in Relay server start path"
else
  # Ensure there is no unconditional listener create at type init / load time.
  if rg -n 'private var listener: NWListener\?' "$RELAY_SWIFT" >/tmp/relay-listener-prop.txt; then
    ok "listener stored as optional (nil when relay off)"
    cat /tmp/relay-listener-prop.txt
  else
    bad "expected optional listener property"
  fi
  # Code-level: start() is the only place that constructs NWListener
  start_line=$(rg -n 'func start\(' "$RELAY_SWIFT" | head -1 | cut -d: -f1 || true)
  for line in $(printf '%s\n' "$listener_hits" | cut -d: -f1); do
    if [[ -n "$start_line" && "$line" -lt "$start_line" ]]; then
      bad "NWListener( at line $line appears before start() at $start_line"
    else
      ok "NWListener( at line $line is at/after start() (line ${start_line:-?})"
    fi
  done
fi

# --- docs: no unguarded 0.0.0.0 without mTLS requirement ---
README="${ROOT}/README.md"
if [[ -f "$README" ]]; then
  if rg -n '0\.0\.0\.0' "$README" | rg -vi 'mTLS|mutualTLS|mutual TLS|forbid|must not|do not|cấm|without mTLS|only with' >/tmp/relay-readme-unsafe.txt; then
    # Still allow mentions that are immediately qualified; flag bare "set bind to 0.0.0.0" style.
    if rg -n 'Set `"0\.0\.0\.0"`|change.*"bind".*0\.0\.0\.0|bind to 0\.0\.0\.0' "$README" >/tmp/relay-readme-instruct.txt; then
      # Accept if same section requires mutualTLS
      if rg -n '0\.0\.0\.0' -A3 -B3 "$README" | rg -qi 'mutualTLS|mutual TLS|mTLS'; then
        ok "README mentions 0.0.0.0 only with mTLS context nearby"
      else
        bad "README still instructs 0.0.0.0 without adjacent mTLS requirement"
        cat /tmp/relay-readme-instruct.txt
      fi
    else
      ok "README has no bare set-bind-to-0.0.0.0 instruction"
    fi
  else
    ok "README 0.0.0.0 mentions are guarded / absent from unguarded scan"
  fi
fi

say ""
if [[ "$FAIL" -eq 0 ]]; then
  ok "all host asserts passed"
  exit 0
fi
bad "one or more asserts failed"
exit 1
