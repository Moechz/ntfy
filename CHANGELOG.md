# Changelog

All notable user-visible changes to the ntfy TOS application package.

## 2.38.2-1 — 2026-11-25

Review remediation of 2.38.1-1 (x86_64 review: C3/L01/L03/V1; aarch64 review:
D18/F2/F7/S11). Upstream base moved 2.38.1 → 2.38.2, so the packaging iteration restarts
at 1. **The host port stays 8034:8080 (RUNBOOK §12: a port collision is not a defect).**

### Fixed

- **D18 / F2 — container never reached a running state.** The environment set
  `NTFY_ATTACHMENT_CACHE_DIR` without `NTFY_BASE_URL`, and upstream 2.38.x exits with
  `if attachment-cache-dir is set, base-url must also be set` (verified in
  `cmd/serve.go` and reproduced with the real image: exit code 1, restart loop). The
  attachment directory is no longer forced, so the server starts with its own defaults
  and reaches a stable `Up` state. Attachments are now documented as opt-in: upstream
  requires `base-url` and `attachment-cache-dir` **together**, and the NAS address is not
  known inside the container (see README → “Attachments are opt-in”).
- **F7 — web interface did not work.** Consequence of the crash loop above; the web UI and
  `/v1/health` now answer HTTP 200 (verified in isolated staging).

### Changed

- **T1 — upstream security release.** Image `binwiederhier/ntfy:v2.38.1` → **`v2.38.2`**
  (published 2026-11-24). It fixes a go-smtp memory-exhaustion issue
  (GO-2026-7029) in e-mail publishing, two topic-reservation authorisation holes and
  `X-Forwarded-For` rate-limit spoofing. Image index
  `sha256:ca35419d…b5e716`, amd64 `sha256:cc40cb74…d238ed`, arm64
  `sha256:3783af9a…99ba`.
- **C9 — descriptions now match the delivered app.** The 23-language texts say that
  message content stays local, that the optional integrations are off by default, and
  that attachments are disabled until configured. The old text advertised attachments
  as always available, which the startup rule makes impossible without a base URL.
- **V1 — no root, no exemption.** The container already ran as `1000:1000`; this release
  adds `cap_drop: [ALL]` and `security_opt: ["no-new-privileges:true"]` and documents that
  ntfy needs no root privileges at all. **No Option-1 root exemption is applied for.**
- **S11 — file permissions minimised.** A small entrypoint wrapper sets `umask 077`, makes
  the three data folders `0700` and `cache.db` / `user.db` / `webpush.db` / `server.yml`
  `0600` on every start. This matters because `user.db` stores bcrypt password hashes and
  access tokens in clear. The wrapper `exec`s `ntfy serve`, so the server stays PID 1 and
  `SIGTERM` is handled directly.

### Added

- **C3 / C8 — privacy policy and third-party disclosure.** `PRIVACY.md` rewritten for
  2.38.2: data inventory, storage paths, retention, user rights and deletion channel,
  security measures, and a table of every endpoint that can receive data (Docker Hub,
  optional upstream iOS relay, FCM, web push, SMTP, Twilio, and the browser-side GitHub
  lookup performed by the bundled `/docs/` page) with the exact switch for each. The
  policy states that the **server** performs no update check and no telemetry, and
  discloses the `/docs/` MkDocs widget separately. `help` opens the public policy, and
  `important` in the store listing points to it.
- **C10 — README** completed with repository layout, first start, attachments, third-party
  table, privacy, security/privileges, data & uninstall, build and architecture sections.

### Fixed (packaging compliance)

- **L01 / L03 — language file.** `ntfydocker.lang` is re-rendered for the new version with
  23 sections and all six fields non-empty, **no ASCII semicolon anywhere** (the store's INI
  parser treats `;` as a comment and truncates the value, dropping the closing quote), and
  LF line endings only. `tools/verify.py` now fails the build if an ASCII semicolon or a
  CRLF reappears in the lang file.

### Notes

- Version 2.38.1-1 was withdrawn from the store (it was on hold) and is superseded by this
  release.

## 2.38.1-1 — 2026-11-19

### Changed
- Upstream image `binwiederhier/ntfy:v2.38.1` (was `v2.37.2`; 2.38.1 was released on
  2026-11-16 — the component-refresh item T1).
- **Persistence fixed (item F8).** ntfy keeps its auth database and web-push subscriptions in
  `/var/lib/ntfy` by default, which was not mounted, so user accounts and push subscriptions
  were lost whenever the container was recreated. A third volume
  (`/Volume1/DockerAppData/ntfydocker/lib` → `/var/lib/ntfy`) was added, and the four state
  paths are now pinned in the environment: `NTFY_CACHE_FILE`,
  `NTFY_ATTACHMENT_CACHE_DIR`, `NTFY_AUTH_FILE`, `NTFY_WEB_PUSH_FILE`.
- Descriptions rewritten (item C9): the old text claimed “no account and no third-party
  service”, which hides the opt-in iOS/e-mail integrations, and told users to “add an auth
  file in the config folder”, which is not how ntfy accounts work. The English and both
  Chinese texts now describe the real feature set and the correct way to add users.

### Added
- `PRIVACY.md`, `NOTICE.md`, and README sections for first start, privacy, third-party
  services, licence, runtime files and architecture (items C3, C4, C5, C7, C8, C10).
- `help` in `config.ini` now opens the privacy policy.

### Removed
- The 6 MB `TOSAppSelfTestingTool` binary is no longer tracked in the public repository.

### Known issue (fixed in 2.38.2-1)
- **D18.** Pinning `NTFY_ATTACHMENT_CACHE_DIR` without `NTFY_BASE_URL` makes the upstream
  server exit at startup (`if attachment-cache-dir is set, base-url must also be set`), so
  the container restart-looped and the web UI was unreachable.

## 2.37.2-1 — 2026-11-09

### Added
- First release. ntfy (`binwiederhier/ntfy:v2.37.2`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8034 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/ntfydocker/`.
