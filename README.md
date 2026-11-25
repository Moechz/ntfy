# ntfy-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [ntfy](https://github.com/binwiederhier/ntfy).
>
> This release: **2.38.2-1** — upstream `binwiederhier/ntfy:v2.38.2` (multi-arch).
> It fixes the 2.38.1-1 startup failure (D18/F2/F7) and rectifies the review findings
> C3, C8, C9, L01, L03, S11 and V1. The host port is **unchanged** at 8034.

## What this is

A four-file TOS Docker application archive (`ntfydocker.tar.gz`) that installs ntfy on
TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `ntfydocker`)
- `ntfydocker.lang` — 23-language superset (TOS requires 14), UTF-8, LF line endings and no
  ASCII semicolons (the store's INI parser treats `;` as a comment and truncates values)
- `ntfydocker.svg` — application icon (615 bytes, pure vector)
- `docker-compose.yml` — one service, image `binwiederhier/ntfy:v2.38.2`

## Repository layout

| Path | Purpose |
|---|---|
| `src/config.ini` | App Center metadata (id, version, help URL, port, platform placeholder) |
| `src/ntfydocker.lang` | 23 language sections rendered from `tosapp.json` |
| `src/ntfydocker.svg` | vector icon |
| `src/docker-compose.yml` | the container definition (the wrapper is embedded here at build time) |
| `src/entrypoint.sh` | wrapper: `umask 077`, private data files, then `exec ntfy serve` |
| `scripts/build.sh` | stage → verify → deterministic tar.gz + sha256 for one architecture |
| `scripts/build-dual.sh` | both architectures + official `TOSAppSelfTestingTool -c` |
| `tools/verify.py` | review-standards self-check (layout, metadata, lang, icon, compose) |
| `test/install-and-verify.sh` | on-device end-to-end test (needs root, not run in CI) |
| `tosapp.json` | canonical spec: image, version, descriptions, translations, volumes |
| `PRIVACY.md` | privacy policy (data, retention, rights, third parties, deletion) |
| `NOTICE.md` | licences, image digests, trademark and packaging notices |
| `CHANGELOG.md` | per-version changes, mapped to the review items |
| `README.md` | this file |

## How it works

| | |
|---|---|
| Container image | `binwiederhier/ntfy:v2.38.2` (Docker Hub, multi-arch amd64 + arm64, used unmodified) |
| Open | `http://<NAS-IP>:8034/` (container port 8080) |
| Runs as | non-root `user: "1000:1000"`, `cap_drop: [ALL]`, `no-new-privileges:true` |
| Message cache | `/var/cache/ntfy` → `/Volume1/DockerAppData/ntfydocker/cache` |
| Server config (`server.yml`) | `/etc/ntfy` → `/Volume1/DockerAppData/ntfydocker/config` |
| Users, tokens, web-push subscriptions | `/var/lib/ntfy` → `/Volume1/DockerAppData/ntfydocker/lib` |
| File permissions | `umask 077`, folders `0700`, databases and `server.yml` `0600` |
| Logs | `docker logs ntfydocker` (stdout/stderr) |
| Health check | `GET /v1/health` on container port 8080 |

The upstream image starts `ntfy` as root. The package overrides the user to `1000:1000` and
starts it through a small wrapper (`src/entrypoint.sh`) that sets `umask 077`, tightens the
three data folders to `0700` and the SQLite databases plus `server.yml` to `0600`, and then
`exec`s `ntfy serve`. The server is therefore PID 1 and receives `SIGTERM` directly, so
`docker stop` is clean and no shell stays behind.

Publishing is a plain HTTP request, so any script can notify you:

```bash
curl -d "backup finished" http://<NAS-IP>:8034/nas-backup
```

Read the messages in the web UI at `http://<NAS-IP>:8034/`, in the ntfy phone app (add your
server URL and the topic), or through the API/WebSocket. The web UI and the API share the one
published port.

## First start

The server starts with **no authentication**, exactly like a stock ntfy server: anyone who can
reach port 8034 can publish to and subscribe to every topic. Two ways to deal with that:

1. Keep it on the LAN (the default assumption of this package), or
2. Create a user and lock the server down:

```bash
docker exec -it ntfydocker ntfy user add --role=admin myuser
docker exec -it ntfydocker ntfy access myuser '*' rw
```

Then put `auth-default-access: "deny-all"` in
`/Volume1/DockerAppData/ntfydocker/config/server.yml` and restart the app (the App Center's
stop/start, or `docker restart ntfydocker`).

The user database lives in `lib/user.db` (created `0600`), so accounts and access tokens
survive a reinstall.

## Attachments are opt-in

Upstream refuses to start when `attachment-cache-dir` is set without `base-url` (this was the
2.38.1-1 startup failure: *“if attachment-cache-dir is set, base-url must also be set”*), and
the NAS LAN address is not visible inside the container. The package therefore leaves both
unset and **attachment upload is disabled by default**.

To enable it, create `/Volume1/DockerAppData/ntfydocker/config/server.yml` with both keys and
restart:

```yaml
base-url: "http://192.168.1.10:8034"          # the address you use to open ntfy
attachment-cache-dir: "/var/cache/ntfy/attachments"
```

Files are then stored in `cache/attachments/` (inside the mounted cache volume), created
`0600`, and expire after 3 hours by default (`attachment-expiry-duration`). Remove the two
keys to disable attachments again.

## Third-party services (API disclosure)

The developer operates no server in this path and receives no data. **With the default
configuration the container makes no outbound connection** — there is no telemetry, no
analytics, no advertising, no crash reporting and **no server-side update check**. The ntfy
integrations below are opt-in and must be configured by you in `config/server.yml` (or require
your own app build). One extra row is browser-side only: the bundled documentation page
(`/docs/`, the “Docs” entry in the web UI) carries the MkDocs Material repository widget, which
asks GitHub for the upstream repo's stars/forks and latest release when **you** open it.

| Service | Endpoint | Data sent | Destination / region |
|---|---|---|---|
| Upstream ntfy server (only if `upstream-base-url` is set) | the URL you choose, conventionally `https://ntfy.sh` | a `poll_request` with the message ID and the SHA-256 of the topic URL, for iOS push delivery. Message content stays on your server | the upstream you chose |
| Firebase Cloud Messaging (only if `firebase-key-file` is set **and** you build your own Android app) | `fcm.googleapis.com` | topic name and message metadata for Android push | Google, US |
| Web push (only if the `web-push-*` keys are set, `base-url` is set and a browser subscribes) | the browser vendor's push endpoint | an encrypted push payload plus the subscription endpoint | Google / Mozilla / Apple / Microsoft |
| SMTP (only if `smtp-sender-*` or `smtp-server-*` is set) | the SMTP server you configure | the message / recipient address, or the inbound mail for e-mail publishing | your mail provider |
| Twilio phone calls (only if `twilio-*`, `base-url` and an auth file are set) | `api.twilio.com` | phone number and call/SMS metadata | Twilio, US |
| Bundled docs page (`/docs/`, only when you open it) | `api.github.com/repos/binwiederhier/ntfy` + `/releases/latest` | upstream stars/forks and latest release tag, fetched by your browser (your IP, no instance data) | GitHub, US |
| Image pull at install | `registry-1.docker.io` or your registry mirror | anonymous pull, no user data | Docker Hub, US / your mirror |

`PRIVACY.md` §3 has the same table with the exact configuration keys and how to turn each one
off.

## Privacy

The application runs entirely on your NAS and the developer has no access to its data. The
full policy — what is stored where, retention periods, user rights (access/export, correction,
deletion), security measures, every third-party endpoint and the deletion channel — is in
[PRIVACY.md](PRIVACY.md). The package's `help` field opens that policy directly from the App
Center entry (`config.ini` → `help`), and `important` in the store listing points to it.

| Topic | Detail |
|---|---|
| Data processed | Messages, users/password hashes/tokens, web-push subscriptions, `server.yml`; attachments only if enabled |
| Where | `/Volume1/DockerAppData/ntfydocker/{cache,config,lib}` on your NAS |
| Retention | Messages: cache duration (12 h by default); attachments: 3 h; users/config: until **you** delete them |
| Rights | Copy the data folders (export), manage users via CLI/API (correct), uninstall with “delete data” or remove the folders (delete) |
| Deletion channel | The data folders, or moechz@163.com (answered within 30 days) |

## Security and privileges

- **Non-root, no capabilities.** `user: "1000:1000"`, `cap_drop: [ALL]`,
  `security_opt: ["no-new-privileges:true"]`. The image's own default is root and port 80,
  which is why the package overrides both (uid 1000 + `NTFY_LISTEN_HTTP=:8080`). **No root
  privilege exemption is needed or requested**: ntfy works fully unprivileged.
- **Private state files.** The wrapper sets `umask 077` before the server starts and re-applies
  `0700`/`0600` on every start, because `user.db` contains bcrypt hashes **and access tokens in
  clear**, `cache.db` contains the messages and `server.yml` may contain SMTP/upstream
  credentials.
- **No privileged features.** No `privileged`, no `network_mode: host`, no Docker socket, no
  `cap_add`, no host devices.
- **Fixed image tag, Docker Hub only**, never `:latest`. The image index and per-architecture
  digests are recorded in `NOTICE.md` and `docker-compose.yml`.

## Licence and attributions

| Component | Licence | Notes |
|---|---|---|
| ntfy | Apache-2.0 OR GPL-2.0 (dual) | upstream application, used unmodified inside the image; this package relies on Apache-2.0 |
| Container image `binwiederhier/ntfy:v2.38.2` | Apache-2.0 OR GPL-2.0 (dual) | pulled from Docker Hub at install time |
| This packaging | MIT (see `LICENSE`) | compose file, metadata, translations, wrapper, icon |

“ntfy”, “TerraMaster” and “TOS” are trademarks of their respective owners. This is an
independent community package by Moechz and is not affiliated with the upstream project or
TerraMaster. Full details: [NOTICE.md](NOTICE.md).

## Data and uninstall

Docker packages have no uninstall hook. Uninstalling the app removes the container but keeps
`/Volume1/DockerAppData/ntfydocker/` unless you tick “delete data”. Back up that folder before
removing the app; delete it to remove every message, user, token and subscription.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `cache/cache.db` | message cache (SQLite) | first start | cache size limit (configurable) | rotated by the cache duration |
| `cache/attachments/` | attached files (only if attachments are enabled) | first attachment | attachment size/count limits | removed with its message or after 3 h |
| `config/server.yml` | server configuration (optional) | only if you create it | static | never overwritten by the app |
| `lib/user.db` | users, roles, tokens, per-topic access | first start | one row per user/token | persistent; back it up |
| `lib/webpush.db` | browser web-push subscriptions (only if enabled) | first subscription | expiry after 60 days | persistent |
| `/Volume1/DockerAppData/ntfydocker/` | everything the container writes outside `/tmp` | on first start | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build-dual.sh 2.38.2-1   # both architectures + official check
scripts/build.sh 2.38.2-1 x86_64 # one architecture
scripts/build.sh                 # current version from tosapp.json
```

The build stages the four files, substitutes the version/platform placeholders, embeds the
wrapper into the compose file (escaping `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity, required
fields, 14+ language coverage, version consistency, **no ASCII semicolon in the lang file**,
Docker-Hub-only images, fixed tag, reserved/recommended host ports, non-root user,
per-service healthcheck/TZ/restart, data paths below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no literal secrets,
the embedded entrypoint matching `src/entrypoint.sh`, and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/ntfydocker_x86_64.tar.gz   # official spec check
./TOSAppSelfTestingTool -c out/ntfydocker_aarch64.tar.gz
bash test/install-and-verify.sh                           # on-device E2E (needs root)
```

The official tool is not redistributed in this repository (see `.gitignore`). The isolated
staging test uses a temporary port and a temporary data directory and never touches
`/Volume1/DockerAppData` production data.

## Architectures

The TOS store takes one package per architecture. This release provides both, built from the
same sources by `scripts/build-dual.sh`:

| Architecture | Package | Size | SHA-256 |
|---|---|---|---|
| x86_64 | `ntfydocker_x86_64.tar.gz` | 6533 B | `2835f534cabf9700b1a7915ee63a3b944fceb2a73ace55d15d09d6cf6e67e99f` |
| aarch64 | `ntfydocker_aarch64.tar.gz` | 6533 B | `1fa3f08c8b53a7afa2d2493659ba2a2e1b73ce22e66d2529a0b4317f66d7bef3` |

Both packages pass the official `TOSAppSelfTestingTool -c` check and `tools/verify.py`; the
x86_64 package is also started in the isolated staging environment (`staging passed 3, failed
0`: container running and healthy, HTTP 200 from the web UI, `user=1000:1000`). The upstream
image is a multi-arch manifest list with both `linux/amd64` and `linux/arm64`, so the aarch64
package runs natively.

## Store submission checklist

1. Public GitHub repo (code + README + PRIVACY + NOTICE + LICENSE; internal docs and build
   products are ignored).
2. Release **tag `v2.38.2-1`** with four assets: `ntfydocker_x86_64.tar.gz` + `.sha256` and
   `ntfydocker_aarch64.tar.gz` + `.sha256` (one archive per architecture, architecture suffix
   in the file name).
3. Developer platform: one App record per architecture (`x86_64`, `aarch64`), package type
   Docker, repository URL, version `2.38.2-1`.
4. When resubmitting after a review, put the item-by-item reply in the submission remarks
   (“Rectified per review comments”).

## Limitations

- **No authentication by default** — same as a stock ntfy server. Keep it on the LAN or create
  a user first; see “First start”.
- **Attachments are off by default.** See “Attachments are opt-in”; this is an upstream
  constraint (`base-url` is required), not a packaging choice.
- Phone-app push is instant on Android without any extra service; **iOS** needs an upstream
  server (`ntfy.sh` or your own) because Apple requires the push relay. That is an opt-in
  setting, and it is the only way messages could leave your NAS.
- The message cache is bounded (12 hours by default); ntfy is not a long-term archive. Use a
  subscriber/receiver script if you need history.
- Docker applications cannot mount NAS shared folders by default, and cannot be upgraded in
  place in the App Center: updating means uninstalling and reinstalling, which keeps the three
  data folders.
- The web UI is plain HTTP on the LAN. Put it behind a TLS reverse proxy before exposing it to
  the internet.

## Support

- Issues and questions: <https://github.com/Moechz/ntfy/issues>
- Email: moechz@163.com
- Privacy: [PRIVACY.md](PRIVACY.md) · Licence: [NOTICE.md](NOTICE.md)

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
