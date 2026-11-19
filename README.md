# ntfy-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [ntfy](https://github.com/binwiederhier/ntfy).

## What this is

A four-file TOS Docker application archive (`ntfydocker.tar.gz`) that installs
ntfy on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `ntfydocker`)
- `ntfydocker.lang` — 23-language superset (TOS requires 14)
- `ntfydocker.svg` — application icon (615 bytes, pure vector)
- `docker-compose.yml` — one service, image `binwiederhier/ntfy:v2.38.1`

## How it works

| | |
|---|---|
| Container image | `binwiederhier/ntfy:v2.38.1` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8034/` (container port 8080) |
| Runs as | non-root, `user: "1000:1000"` |
| Message cache and attachments | `/var/cache/ntfy` → `/Volume1/DockerAppData/ntfydocker/cache` |
| Server config (`server.yml`) | `/etc/ntfy` → `/Volume1/DockerAppData/ntfydocker/config` |
| Users, tokens, web-push subscriptions | `/var/lib/ntfy` → `/Volume1/DockerAppData/ntfydocker/lib` |
| Logs | `docker logs ntfydocker` (stdout/stderr) |
| Health check | `GET /v1/health` on container port 8080 |

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
# then restart the package with NTFY_AUTH_DEFAULT_ACCESS=deny-all
```

The user database lives in `lib/user.db`, so accounts and access tokens survive a reinstall.

## Third-party services (API disclosure)

The developer operates no server in this path and receives no data. **With the default
configuration the container makes no outbound connection.** Everything below is opt-in:

| Service | Endpoint | Data sent | Destination / region |
|---|---|---|---|
| Upstream server (only if `NTFY_UPSTREAM_BASE_URL` is set) | the upstream URL, conventionally `ntfy.sh` | the topic name and a poll request, for iOS push delivery; messages stay on your server | the upstream you chose |
| Firebase Cloud Messaging (only if `firebase-key-file` is set) | `fcm.googleapis.com` | topic name and message metadata for Android push | Google, US |
| Web push (only if the web-push keys are set and a browser subscribes) | the browser vendor's push endpoint | an encrypted push payload plus the subscription endpoint | Mozilla / Google / Apple |
| SMTP (only if `smtp-server-*` is set) | the SMTP server you configure | the message, or the inbound mail for e-mail publishing | your mail provider |
| Image pull at install | `registry-1.docker.io` or your registry mirror | anonymous pull | Docker Hub, US / your mirror |

There is no telemetry, no analytics and no advertising SDK. See `PRIVACY.md` §6 for the same
table with more detail.

## Privacy

The application runs entirely on your NAS and the developer has no access to its data. The
full policy — retention period, user rights (access/export, correction, deletion), security
measures, third-party sharing and the deletion channel — is in [PRIVACY.md](PRIVACY.md). The
package's `help` field opens that policy directly from the App Center entry
(`config.ini` → `help`), and the website version at
<https://www.moechz.com/privacy.html> (section 6) covers all applications by this developer.

| Topic | Detail |
|---|---|
| Data processed | Messages and attachments, user database, web-push subscriptions, `server.yml` |
| Where | `/Volume1/DockerAppData/ntfydocker/{cache,config,lib}` on your NAS |
| Retention | Messages: cache duration (12 h by default); users/config: until **you** delete them |
| Rights | Copy the data folders (export), manage users via CLI/API (correct), uninstall with “delete data” or remove the folders (delete) |
| Deletion channel | The data folders, or moechz@163.com (answered within 30 days) |

## Licence and attributions

| Component | Licence | Notes |
|---|---|---|
| ntfy | Apache-2.0 | upstream application, used unmodified inside the image |
| Container image `binwiederhier/ntfy:v2.38.1` | Apache-2.0 | pulled from Docker Hub at install time |
| This packaging | MIT (see `LICENSE`) | compose file, metadata, translations, icon |

“ntfy”, “TerraMaster” and “TOS” are trademarks of their respective owners. This is an
independent community package by Moechz and is not affiliated with the upstream project or
TerraMaster. Full details: [NOTICE.md](NOTICE.md).

## Design highlights

- **Non-root, including the port.** `user: "1000:1000"` and `NTFY_LISTEN_HTTP=:8080`; the
  image's own default is port 80, which an unprivileged container cannot bind.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no
  `network_mode: host`, no Docker socket, no `cap_add`.
- **Health check** on `/v1/health`, the server's own liveness endpoint.
- **Explicit state paths.** `NTFY_CACHE_FILE`, `NTFY_ATTACHMENT_CACHE_DIR`, `NTFY_AUTH_FILE`
  and `NTFY_WEB_PUSH_FILE` are pinned inside the three mounted folders, because ntfy's own
  defaults put the user database in `/var/lib/ntfy` — which would otherwise be lost on every
  container recreation.
- **One HTTP port for UI and API.**
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a
  timestamp, plus the review-standards self-check.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data directory; the
container-internal `/tmp` is discarded with the container. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `cache/cache.db` | message cache (SQLite) | first message | cache size limit (configurable) | rotated by the cache duration |
| `cache/attachments/` | attached files | first attachment | attachment size/count limits | removed with its message |
| `config/server.yml` | server configuration (optional) | only if you create it | static | never overwritten by the app |
| `lib/user.db` | users, roles, tokens, per-topic access | first `ntfy user` command | one row per user/token | persistent; back it up |
| `lib/webpush.db` | browser web-push subscriptions | first browser subscription | expiry after 60 days | persistent |
| `/Volume1/DockerAppData/ntfydocker/{cache,config,lib}` | everything the container writes outside /tmp | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Architectures

The TOS store takes one package per architecture. This release provides both, built from the
same sources by `scripts/build-dual.sh`:

| Architecture | Package | Size | SHA-256 |
|---|---|---|---|
| x86_64 | `ntfydocker_x86_64.tar.gz` | 4819 B | `23dff97856be7779d4e19506d7f2b4811f3ee6816615892a204d7bdb6c5e4a98` |
| aarch64 | `ntfydocker_aarch64.tar.gz` | 4819 B | `cfc4b5486f0f40719de8ca43e66e03570dd40861b9b253f68412b54445f6a3e5` |

Both packages pass the official `TOSAppSelfTestingTool -c` check and the package's own
`tools/verify.py`. The on-device E2E was run for `2.37.2-1`; the `2.38.1` image bump is
pending a fresh on-device run (Docker applications have to be installed with the official
tool's `-i` mode, not through the App Center install page).

## Build

```bash
scripts/build-dual.sh 2.38.1-1   # both architectures + official check
scripts/build.sh 2.38.1-1 x86_64 # one architecture
scripts/build.sh                 # current version from tosapp.json
```

The build stages the four files, substitutes the version/platform placeholders, removes
CRLF/BOM/AppleDouble, then runs `tools/verify.py`, a review-standards self-check (archive
layout, JSON validity, required fields, 14+ language coverage, version consistency,
Docker-Hub-only images, fixed tag, reserved/recommended host ports, non-root user,
per-service healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no literal secrets
and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/ntfydocker_x86_64.tar.gz   # official spec check
./TOSAppSelfTestingTool -i out/ntfydocker_x86_64.tar.gz   # install on this machine
bash test/install-and-verify.sh                           # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual install page (it
> accepts `.deb` only); the official self-testing tool's `-i` mode or `docker compose` are the
> only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README + PRIVACY + NOTICE + LICENSE; internal docs and build
   products are ignored).
2. Release **tag `v2.38.1-1`** with four assets: `ntfydocker_x86_64.tar.gz` + `.sha256` and
   `ntfydocker_aarch64.tar.gz` + `.sha256` (one archive per architecture, architecture suffix
   in the file name).
3. Developer platform: one App record per architecture (`x86_64`, `aarch64`), package type
   Docker, repository URL, version `2.38.1-1`.
4. When resubmitting after a review, put the item-by-item reply in the submission remarks.

## Limitations

- **No authentication by default** — same as a stock ntfy server. Keep it on the LAN or create
  a user first; see “First start”.
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
