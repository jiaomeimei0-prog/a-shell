# PR3 evidence — remove sshd binary + UI

**Branch:** `cursor/remove-sshd-45fd`  
**Date:** 2026-11-28 (Asia/Saigon)  
**Runtime iOS:** `PENDING_USER_DEVICE`

## Note on `xcfs/frameworks.json`

This tip has **no** `xcfs/frameworks.json` (only `xcfs/Package.swift` + `Package.resolved` + `Sources/build`). sshd was removed from `Package.swift` binaryTargets. No frameworks.json entry to delete.

## Commands + observed results

```text
$ rg -n 'sshd' xcfs/Package.swift
(none)

$ rg -n 'sshd' a-Shell.xcodeproj/project.pbxproj
(none)

$ rg -nI 'sshd' --glob '!SwiftTerm/**' --glob '!Resources/vim/**' --glob '!Resources/man/**'
# only historical comments in ContentView/SceneDelegate after removal

$ rg -n 'name: "ssh_cmd"|name: "ssh_cmdA"|name: "ssh_agent"' xcfs/Package.swift
49:            name: "ssh_cmd",
54:            name: "ssh_cmdA",
59:            name: "ssh_agent",

$ python3 -c "import plistlib; from pathlib import Path
d=plistlib.loads(Path('Resources/commandDictionary.plist').read_bytes())
print(len(d), 'sshd' in d, [k for k in d if str(k).startswith('ssh') or k in ('scp','sftp')])"
158 False ['scp', 'sftp', 'ssh', 'ssh-add', 'ssh-agent', 'ssh-keygen']
```

Catalogue stays **158** (no `sshd` plist key existed). Client tools kept: ssh / scp / sftp / ssh-keygen / ssh-agent / ssh-add via `ssh_cmd` / `ssh_cmdA` / `ssh_agent`.

## Files changed

- `xcfs/Package.swift` — drop `sshd` binaryTarget
- `a-Shell.xcodeproj/project.pbxproj` — drop sshd.xcframework file ref/group
- `a-Shell/ContentView.swift` — Relay-only ServiceStatus UI
- `a-Shell/SceneDelegate.swift` — no `sshd on|off`; reject kind `ssh`
- `Docs/sshd-removal-note.md` — history

## Historical leftovers (allowed)

- OpenSSH manpage cross-refs to `sshd(8)` / `sshd_config(5)`
- Vim `sshdconfig` syntax (editor support for a file type, not the binary)

## PENDING_USER_DEVICE

- App builds without sshd.xcframework
- Remote Access sheet shows Relay only
- `help -l` has no `sshd`; ssh/scp/sftp/ssh-keygen/ssh-agent/ssh-add remain
