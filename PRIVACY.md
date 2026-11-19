# Privacy Policy — ntfy for TerraMaster TOS (`ntfydocker`)

**Last updated:** 19 November 2026
**Data controller / contact:** Moechz — moechz@163.com

This policy covers the TOS application `ntfydocker` (the “app”) and its packaging. The app
runs the official `binwiederhier/ntfy` container image, unmodified, on your own NAS.

## 1. Summary

- The app runs **entirely on your NAS**. The developer does not receive, collect or have
  access to your data, and operates no server that the app talks to.
- **By default the app contacts no third-party service at all.** The optional integrations
  that do (iOS push via an upstream server, e-mail publishing via SMTP, Firebase or browser
  web push) are off unless you configure them — see §6.
- No telemetry, no analytics, no advertising, no account with the developer.

## 2. What data is processed

| Container path | Stored on the NAS at |
|---|---|
| `/var/cache/ntfy` | `/Volume1/DockerAppData/ntfydocker/cache` |
| `/etc/ntfy` | `/Volume1/DockerAppData/ntfydocker/config` |
| `/var/lib/ntfy` | `/Volume1/DockerAppData/ntfydocker/lib` |

The application processes:

- **Messages and their metadata** you or your scripts publish: topic name, message text,
  title, tags/priorities, timestamps, and any attached file. They are held in the message
  cache (`cache/cache.db`, default retention 12 hours) and attachments
  (`cache/attachments/`).
- **Access-control data** if you create users: usernames, roles, password hashes, access
  tokens and per-topic permissions (`lib/user.db`).
- **Web-push subscriptions** if a browser subscribes (`lib/webpush.db`).
- **Server configuration** (`config/server.yml`), if you create one.
- **Subscriber IP addresses** for rate limiting and the “visitor” counters, held in memory
  or in the cache, not written to a separate file.

No data is sent to the developer. Nothing is uploaded anywhere unless you configure an
optional integration from §6.

## 3. Retention period

- **Messages:** the cache duration (12 hours by default) and the cache size limit decide when
  a message is dropped; both are settings of the server. Delayed messages may wait up to
  three days.
- **Attachments:** removed with the message they belong to, or by the cache cleaner.
- **Users, tokens, web-push subscriptions, configuration:** kept until **you** delete them.
  Uninstalling the app keeps the folders unless you tick “delete data”.
- **Logs:** written to the container's stdout/stderr and rotated by Docker according to the
  NAS log driver; stopping and recreating the container discards them.

## 4. Your rights and the deletion channel

| Right | How |
|---|---|
| Access / export | Copy `/Volume1/DockerAppData/ntfydocker/` — it is the complete state of the app. Individual messages can be exported through the API (`?since=…`). |
| Correct | Edit the topic messages you publish, manage users/tokens with `docker exec -it ntfydocker ntfy user …`, edit `config/server.yml`. |
| Delete | Uninstall the app with “delete data”, remove `/Volume1/DockerAppData/ntfydocker/`, or delete a single message/user through the API or the CLI. |
| Assistance | Email **moechz@163.com** with the subject “ntfy data request”; a reply follows within 30 days. |

The developer holds no copy of your data, so deletion is normally completed by removing the
folder on your own NAS. The e-mail channel exists for questions and for requests about the
website or the publishing records.

## 5. Security measures

- The container runs as **uid 1000**, never root; no `privileged`, no `cap_add`, no host
  network, no Docker socket; only its own three data folders are mounted.
- Only one port is published (`8034` on the NAS → `8080` in the container).
- **Authentication is off by default**, exactly like a stock ntfy server: anyone who can
  reach the port can publish and subscribe to any topic. Keep it on your LAN, or create a
  user and set `NTFY_AUTH_DEFAULT_ACCESS=deny-all` before exposing it.
- The image tag is **pinned** (`binwiederhier/ntfy:v2.38.1`); the package is rebuilt when
  upstream ships fixes.
- The data folders are owned by the application user. They are only as safe as your NAS:
  anyone who can read them can read the cached messages and the user database. Keep the
  folders out of shared folders and off backups you do not control.
- The web UI is served over **plain HTTP on your LAN**. Put it behind a TLS reverse proxy
  before exposing it to the internet — and turn on authentication first.

## 6. Third-party sharing and API disclosure

The developer shares nothing and receives nothing. With the default configuration the
application makes **no outbound connection**. The rows below are the integrations a user can
enable deliberately:

| Service | Endpoint | Data sent | Destination / region |
|---|---|---|---|
| Upstream server (only if `NTFY_UPSTREAM_BASE_URL` is set) | the upstream's URL, conventionally `ntfy.sh` | the topic name and a poll request **for iOS push delivery**; messages stay on your server | the upstream you chose |
| Firebase Cloud Messaging (only if `firebase-key-file` is set) | `fcm.googleapis.com` | topic name and message metadata for Android push | Google, US |
| Web push (only if the web-push keys are set and a browser subscribes) | the browser vendor's push endpoint (Mozilla, Google, Apple) | an encrypted push payload and the subscription endpoint | that vendor |
| SMTP (only if `smtp-server-*` is set, for published e-mail or e-mail publishing) | the SMTP server you configure | the message / the inbound mail | your mail provider |
| Image pull at install | `registry-1.docker.io` or your registry mirror | anonymous pull | Docker Hub, US / your mirror |

There is no telemetry, no analytics and no advertising SDK. The upstream project states the
same for the software itself:
<https://github.com/binwiederhier/ntfy/blob/v2.38.1/docs/privacy.md>.

## 7. Children

The app is a self-hosted messaging service and is not directed at children.

## 8. Changes

Material changes are published in this file and reflected in the “Last updated” date.

## 9. Contact

- Moechz — **moechz@163.com**
- Package repository and issues: <https://github.com/Moechz/ntfy>
- Website privacy page: <https://www.moechz.com/privacy.html>
- Upstream project: <https://github.com/binwiederhier/ntfy>
