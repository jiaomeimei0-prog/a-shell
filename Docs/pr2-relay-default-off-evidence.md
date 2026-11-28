# PR2 evidence — Relay default off + bind loopback

**Branch:** `cursor/relay-default-off-45fd`  
**Date:** 2026-11-28 (Asia/Saigon)  
**Runtime iOS:** `PENDING_USER_DEVICE` (no NWListener when `enabled=false` on device)

## Host asserts

```text
$ bash scripts/assert_relay_defaults.sh
## assert_relay_defaults (2026-11-28T04:19:14Z)
file: /agent/repos/a-shell/a-Shell/Relay.swift
PASS: default enabled=false
139:    var enabled = false
PASS: default bind="127.0.0.1"
140:    var bind = "127.0.0.1"
PASS: autostart only calls start() when configuration.enabled
658:                if configuration.enabled { try self.start(configuration) }
NWListener( sites:
300:        let listener = try NWListener(using: parameters)
PASS: listener stored as optional (nil when relay off)
271:    private var listener: NWListener?
PASS: NWListener( at line 300 is at/after start() (line 299)
PASS: README 0.0.0.0 mentions are guarded / absent from unguarded scan

PASS: all host asserts passed
```

## Docs

- README: forbid `0.0.0.0` / `::` without `mutualTLS: true`; token treated as credential.
- In-app `relay status` / Remote access copy aligned (no bare “bind 0.0.0.0” when mTLS off).

## Out of scope

- No Relay strip; mTLS defaults unchanged (`mutualTLS = true`).
- TLS/ATS (PR1), sshd removal (PR3).

## PENDING_USER_DEVICE

- Fresh install: no TCP acceptor on RelayServerPort until `relay on`
- `relay off` tears down NWListener
