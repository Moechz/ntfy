# Changelog

All notable user-visible changes to the ntfy TOS application package.

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

## 2.37.2-1 — 2026-11-09

### Added
- First release. ntfy (`binwiederhier/ntfy:v2.37.2`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8034 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/ntfydocker/`.
