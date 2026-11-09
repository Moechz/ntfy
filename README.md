# ntfy-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [ntfy](https://github.com/binwiederhier/ntfy).

## What this is

A four-file TOS Docker application archive (`ntfydocker.tar.gz`) that installs
ntfy on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `ntfydocker`)
- `ntfydocker.lang` — 23-language superset (TOS requires 14)
- `ntfydocker.svg` — application icon (615 bytes, 3 SVG elements)
- `docker-compose.yml` — one service, image `binwiederhier/ntfy:v2.37.2`

## How it works

| | |
|---|---|
| Container image | `binwiederhier/ntfy:v2.37.2` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8034/` (container port 8080) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/var/cache/ntfy` → `/Volume1/DockerAppData/ntfydocker/cache`, `/etc/ntfy` → `/Volume1/DockerAppData/ntfydocker/config` |
| Logs | `docker logs ntfydocker` (stdout/stderr) |

`/var/cache/ntfy` (mounted from `DockerAppData/ntfydocker/cache`) keeps the message cache and any attachments; `/etc/ntfy` (mounted from `.../config`) is where you put `server.yml` to add users, access control or a base URL.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 8080.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Non-root by port choice.** The image defaults to port 80, which an unprivileged container cannot bind; the package starts `ntfy serve` with `NTFY_LISTEN_HTTP=:8080` instead.
- **No external database.** The message cache is a file-based store under the cache volume.
- **One HTTP port for UI and API.** Publishing is a plain PUT/POST, so scripts and the phone app need nothing but the URL.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `/Volume1/DockerAppData/ntfydocker/cache` | ntfy application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/ntfydocker/config` | ntfy application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/ntfydocker.tar.gz + .sha256
scripts/build.sh 2.37.2-2   # packaging iteration bump
scripts/build.sh 2.37.2-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/ntfydocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v2.37.2-1`**, assets `ntfydocker.tar.gz` +
   `ntfydocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `ntfydocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `2.37.2-1` → automated validation → review.

## License / branding

ntfy is distributed by its upstream authors under **Apache-2.0**. The container image is the official image from Docker Hub (`binwiederhier/ntfy:v2.37.2`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

- No authentication out of the box: anyone reaching the port can publish to any topic. Add an auth file or keep it on the LAN.
- The web UI is plain HTTP; use a TLS reverse proxy before exposing it to the internet.
- Attachment links and some notification links use ntfy's base-url setting; set it in `server.yml` if your NAS address changes (the package does not guess your NAS IP).

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
