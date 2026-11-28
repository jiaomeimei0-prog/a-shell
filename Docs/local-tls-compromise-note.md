# Local TLS material — compromised (do not reuse)

**Date:** 2026-11-28

The following files were historically committed in this repository and must be treated as **public / compromised**:

- `localCertificate.pfx` (passphrase was the literal string `password`)
- `localCertificate.pem`
- `localCertificateKey.pem`

They are **removed from git tracking**. Do **not** restore them into the Bundle or re-commit private keys.

## Replacement (PR TLS/ATS)

- WASM HTTPS loopback now uses a **runtime-generated** PKCS#12 under Application Support (`LocalHTTPS/identity.p12`).
- Passphrase is random and stored in the **Keychain** (`AsheKube.a-Shell.localLoopbackTLS`).
- SAN: `DNS:localhost,IP:127.0.0.1`.
- `WKWebView` auth challenges only pin-trust that leaf on `localhost` / `127.0.0.1`; otherwise `.performDefaultHandling`.

## Verification status

- Host/static: ATS ArbitraryLoads removed; bundle certs absent from `git ls-files`.
- WASM `https://127.0.0.1:<port>/` after change: **`PENDING_USER_DEVICE`** (requires iOS Simulator/device).
