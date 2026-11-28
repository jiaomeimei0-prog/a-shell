# PR1 evidence — TLS / ATS / local cert (host-side)

**Branch:** `cursor/tls-ats-local-cert-45fd`  
**Date:** 2026-11-28 (Asia/Saigon)  
**Runtime iOS:** `PENDING_USER_DEVICE`

## Pre-patch line confirmation

```text
$ rg -n 'func webView\(_ webView: WKWebView, didReceive challenge' a-Shell/SceneDelegate.swift
6338:    func webView(_ webView: WKWebView, didReceive challenge: ...
```

`didReceive` is at **6338** on this revision (not 6379). AppDelegate local-server TLS load was at **45–46**.

## Commands + observed results

### ATS ArbitraryLoads gone; LocalNetworking present

```text
$ rg -n 'NSAllowsArbitraryLoads' --glob '*.plist'
(none)

$ python3 -c "import plistlib; from pathlib import Path
for p in ['a-Shell/Info.plist','a-Shell-mini-Info.plist']:
  print(p, plistlib.loads(Path(p).read_bytes()).get('NSAppTransportSecurity'))"
a-Shell/Info.plist {'NSAllowsLocalNetworking': True}
a-Shell-mini-Info.plist {'NSAllowsLocalNetworking': True}
```

### Bundle certs not tracked

```text
$ git ls-files | rg -i 'localCertificate|\.pfx$'
(none tracked)
```

### No trust-all force-unwrap

```text
$ rg -n 'URLCredential\(trust: challenge\.protectionSpace\.serverTrust!' a-Shell/SceneDelegate.swift
(none)
```

Pinned path uses `ServerTrust` + host ∈ {localhost, 127.0.0.1} + leaf SHA256 match; else `.performDefaultHandling`.

### pbxproj / gitignore

```text
$ rg -n 'localCertificate' a-Shell.xcodeproj/project.pbxproj
pbxproj: none

$ rg -n 'localCertificate' .gitignore
localCertificate.pfx
localCertificate.pem
localCertificateKey.pem
```

## Files changed (this PR)

- `a-Shell/Relay.swift` — `generatePKCS12` + `LocalLoopbackTLS`
- `a-Shell/AppDelegate.swift` — `LocalLoopbackTLS.prepareIdentity()`
- `a-Shell/SceneDelegate.swift` — pin-trust `didReceive`
- `a-Shell/Info.plist`, `a-Shell-mini-Info.plist` — ATS
- `a-Shell.xcodeproj/project.pbxproj` — drop Copy Bundle Resources certs
- `.gitignore` — ignore legacy cert names
- `Docs/local-tls-compromise-note.md` — compromised key note
- deleted (tracked): `localCertificate.pfx`, `localCertificate.pem`, `localCertificateKey.pem`

## PENDING_USER_DEVICE

- WASM `https://127.0.0.1:<wasm-port>/` load after ATS + pin-trust
- Valid public HTTPS still loads via `.performDefaultHandling`
- Keychain passphrase persistence across relaunch
