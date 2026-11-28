# sshd removed (history)

**Date:** 2026-11-28

The in-app OpenSSH **server** binary (`sshd.xcframework` from ios_system v3.0.5) and its Remote Access on/off UI are removed from this fork.

## Kept (client tooling)

- Binary targets: `ssh_cmd`, `ssh_cmdA`, `ssh_agent`
- Commands: `ssh`, `scp`, `sftp`, `ssh-keygen`, `ssh-agent`, `ssh-add`
- Catalogue `Resources/commandDictionary.plist` remains **158** entries (there was never an `sshd` plist key)

## Not present on this tip

- `xcfs/frameworks.json` — absent; only `Package.swift` listed binaryTargets

## Replacement remote execution

Use **Relay** (HTTPS + token; mutual TLS by default). See README “Run commands remotely with relay”.
