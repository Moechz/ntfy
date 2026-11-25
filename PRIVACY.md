# Privacy Policy — ntfy for TerraMaster TOS (`ntfydocker`)

**Last updated:** 25 November 2026
**Version covered:** 2.38.2-1 (image `binwiederhier/ntfy:v2.38.2`)
**Data controller / contact:** Moechz — moechz@163.com

This policy covers the TOS application `ntfydocker` (the “app”) and its packaging. The app
runs the official `binwiederhier/ntfy` container image, unmodified, on your own NAS. It is an
independent community package, not affiliated with the upstream ntfy project or TerraMaster.

## 1. Summary

- The app runs **entirely on your NAS**. The developer receives no data, operates no server
  that the app talks to, and has no way to access your instance.
- **The ntfy server itself contacts no third-party service by default.** No telemetry, no
  analytics, no advertising, no crash reporting, no server-side update check, no account with
  the developer.
- The **bundled documentation page** (the “Docs” entry in the web UI, served at `/docs/`) is a
  static MkDocs site. Its header asks GitHub for the upstream repository's star/fork counts and
  latest release tag — a request made by **your browser**, only when you open that page. It is
  the only “latest release” lookup in the package; see §3.
- Every integration that could send data off the NAS (upstream iOS relay, Firebase, web push,
  SMTP, Twilio) is **off unless you configure it yourself** — see §3.
- **File attachments are off by default.** Upstream only accepts an attachment directory when
  `base-url` is also set, and the NAS address is not known inside the container. See §3.1 for
  the two lines that enable them.
- The only data the developer holds is the public package itself (code, README, this policy)
  and ordinary publishing records on GitHub (repository, release assets, tags).

## 2. What data is processed, and where

Everything the container writes lives under `/Volume1/DockerAppData/ntfydocker/` on your NAS.
The container's own `/tmp` is discarded when the container is recreated.

| Data | Content | Stored at | Default retention |
|---|---|---|---|
| Messages | topic name, message body, title, priority/tags, timestamps, delay | `cache/cache.db` (SQLite) | 12 hours (`cache-duration`), configurable. Delayed messages may wait up to 3 days |
| Attachments (only if enabled) | file name, size, MIME type, file bytes | `cache/attachments/` | 3 hours after upload (`attachment-expiry-duration`), or with the message |
| Users, roles, access rules | username, **bcrypt password hash** (never the password), role, per-topic ACL, creation time | `lib/user.db` | until **you** delete the user |
| Access tokens | the **token value itself** (ntfy stores it as issued, not hashed), label, last-access time and the IP address of the last use, expiry | `lib/user.db` | until expiry or deletion (at most 60 tokens per user) |
| Web-push subscriptions (only if web push is enabled) | browser push endpoint, subscription keys | `lib/webpush.db` | 60 days, then expired |
| Server configuration (only if you create it) | users, ACL, SMTP credentials, upstream URL/token, Firebase key path, base URL | `config/server.yml` | until **you** edit or delete the file |
| Logs | startup and operational messages, errors; message content is not logged at the default level | container stdout/stderr | rotated by the Docker log driver on the NAS |
| Client IP addresses | used in memory for rate limiting; the last IP of a token is written to `user.db` | memory, `lib/user.db` | memory: process lifetime. `user.db`: until the token is deleted |

No data is sent to the developer. Nothing is uploaded anywhere unless you enable one of the
optional integrations in §3. There is no “phone home”, no licence check and no server-side
update check: the container never contacts GitHub, Docker Hub or the ntfy project on its own.
The web UI only polls `/v1/config` on your own server. The single exception is your **browser**
loading the bundled `/docs/` page, which runs the MkDocs Material repository widget described
in §3 — it asks GitHub for the upstream repo's stars/forks and latest release.

## 3. What can leave the NAS (third-party endpoints)

With the default configuration the answer is **nothing**. The app contains no credentials and
no preconfigured remote endpoint. The table lists every integration a user can turn on, the
endpoint it uses, the data it sends and how to turn it off. The ntfy integrations require you
to edit `/Volume1/DockerAppData/ntfydocker/config/server.yml` (or build your own app) and none
is on by default. The documentation row is the one exception — it fires in **your browser**
only when you open `/docs/`, and it sends no instance data.

| Integration | Endpoint | Data sent | Destination / region | How to enable / disable |
|---|---|---|---|---|
| Container image pull (install and update only) | `registry-1.docker.io` (or the registry mirror configured on your NAS) | anonymous image pull, no user data | Docker Hub, US / your mirror | performed by the App Center, not by the app. It stops when the image is present |
| Bundled documentation page (“Docs” in the web UI, `/docs/`) | `api.github.com/repos/binwiederhier/ntfy` and `.../releases/latest` | the docs theme (MkDocs Material) reads the upstream repository's star/fork counts and latest release tag. Your browser sends the request, so GitHub sees your IP. No instance data, no message content | GitHub, US | passive: only when **you** open `/docs/`. The app UI at `/` never calls it. Avoid `/docs/` or block `api.github.com` to prevent it |
| iOS instant notifications, via an upstream ntfy server you choose | the URL you set in `upstream-base-url`, conventionally `https://ntfy.sh` | a `poll_request` containing only the message ID and the SHA-256 of the topic URL. **Message content stays on your NAS** | the upstream operator you chose | opt-in: set `upstream-base-url` **and** `base-url` in `server.yml`. Remove both to disable. Without it iOS delivery may take hours |
| Firebase Cloud Messaging (FCM) | `fcm.googleapis.com` | topic name and message metadata, for Android delivery | Google, US | opt-in and rarely needed: set `firebase-key-file` **and** build your own Android APK. Remove the key to disable |
| Browser web push | the push endpoint of the browser vendor (Google for Chrome/Edge, Mozilla for Firefox, Apple for Safari) | an encrypted push payload and your subscription endpoint | that vendor | opt-in: requires `web-push-*` keys, `web-push-file` **and** `base-url`, plus a browser that subscribes. Delete the subscription to stop |
| Outgoing e-mail (notifications, account mail) | the SMTP server you configure (`smtp-sender-*`) | recipient address and the message or notification | your mail provider | opt-in. Remove `smtp-sender-addr` to disable |
| E-mail publishing (inbound mail becomes a message) | the SMTP listener you configure (`smtp-server-*`) | the inbound mail | your mail provider / the sender | opt-in. Remove `smtp-server-listen` to disable |
| Phone calls / SMS verification | `api.twilio.com` | phone number and call/SMS metadata | Twilio, US | opt-in: set the `twilio-*` keys **and** `base-url` **and** an auth file. Remove them to disable |
| Attachments (local only) | no network endpoint | uploaded file bytes, stored locally | **stays on the NAS** | off by default. Set `base-url` **and** `attachment-cache-dir` in `server.yml` to enable |

Notes:

- The upstream ntfy server does not phone home. The **Android app** connects directly to your
  server (instant delivery on a self-hosted host does not use FCM). The **iOS app** needs a
  central relay because Apple restricts background processing, which is why the optional
  `upstream-base-url` row exists.
- When you publish a message with `X-Email` or `X-Call`, the recipient address or phone number
  is processed by your SMTP provider or Twilio respectively — the app does not contact them
  unless you configured those keys.
- The upstream project's own privacy policy for the hosted `ntfy.sh` service is a different
  document: <https://docs.ntfy.sh/privacy/>. It does not apply to this self-hosted package,
  except when you deliberately point `upstream-base-url` at `ntfy.sh`.

## 4. Retention period

- **Messages:** the cache duration (12 hours by default) and the cache size limit decide when a
  message is dropped. Delayed messages may wait up to three days. Setting `cache-duration: 0`
  disables the on-disk cache entirely.
- **Attachments:** deleted three hours after upload by default, or together with their message.
- **Users, tokens, ACLs, web-push subscriptions and `server.yml`:** kept until **you** delete
  them. Uninstalling the app keeps the data folders unless you tick “delete data”.
- **Logs:** written to the container's stdout/stderr and rotated by the NAS Docker log driver.
  They are discarded when the container is recreated.

## 5. Your rights and the deletion channel

| Right | How |
|---|---|
| Access / export | Copy `/Volume1/DockerAppData/ntfydocker/` — it is the complete state of the app. Messages can also be exported through the API (`?since=…`), and users/tokens listed with `docker exec -it ntfydocker ntfy user list` / `ntfy token list` |
| Correct | Edit the messages you publish, manage users/tokens/ACL with `docker exec -it ntfydocker ntfy …`, edit `config/server.yml` |
| Delete | Delete a single message or user through the API/CLI, remove `/Volume1/DockerAppData/ntfydocker/`, or uninstall the app with “delete data” |
| Restrict | Keep the app on the LAN, enable authentication and `auth-default-access: deny-all`, and leave the §3 integrations off |
| Assistance | Email **moechz@163.com** with the subject “ntfy data request”; a reply follows within 30 days |

The developer holds no copy of your data, so deletion is normally completed by removing the
folder on your own NAS. The e-mail channel exists for questions and for requests about the
public repository and the publishing records.

## 6. Security measures

- The container runs as **uid 1000 (non-root)**, with **all Linux capabilities dropped** and
  `no-new-privileges` set. No `privileged`, no host network, no Docker socket, no `cap_add`.
- The entrypoint sets **`umask 077`**, tightens the three data folders to **0700** and the
  databases (`cache.db`, `user.db`, `webpush.db`) plus `server.yml` to **0600** on every start.
  This matters because `user.db` holds bcrypt password hashes **and access tokens in clear**.
- Only one port is published (`8034` on the NAS → `8080` in the container).
- The image tag is pinned (`binwiederhier/ntfy:v2.38.2`) and the package is rebuilt when
  upstream ships fixes (this release is the 2.38.2 security update).
- **Authentication is off by default**, exactly like a stock ntfy server: anyone who can reach
  the port can publish and subscribe to any topic. Keep it on your LAN, or create a user and
  set `auth-default-access: deny-all` before exposing it.
- The web UI is served over **plain HTTP on your LAN**. Put it behind a TLS reverse proxy
  before exposing it to the internet, and turn on authentication first.
- The data folders are owned by the application user. Anyone who can read them can read the
  cached messages and the user database, so keep them out of shared folders and off backups
  you do not control.

## 7. Children

The app is a self-hosted messaging service and is not directed at children.

## 8. Changes

Material changes are published in this file and reflected in the “Last updated” date. The full
history is in the public repository: <https://github.com/Moechz/ntfy/commits/main/PRIVACY.md>.

## 9. Contact

- Moechz — **moechz@163.com**
- Package repository, issues and this policy:
  <https://github.com/Moechz/ntfy>
- Public copy of this policy:
  <https://github.com/Moechz/ntfy/blob/main/PRIVACY.md>
- Upstream project: <https://github.com/binwiederhier/ntfy>
