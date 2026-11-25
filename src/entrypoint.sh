#!/bin/sh
# ===========================================================================
# ntfy entrypoint wrapper for TerraMaster TOS 7
# ===========================================================================
# The upstream image is used unmodified. This wrapper only does two things:
#
#   1. It tightens the permissions of everything that holds user data. The
#      upstream server is fine with a permissive umask, so without this the
#      SQLite databases are created 0644 and every local user on the NAS can
#      read them: cache.db holds the cached messages, user.db holds password
#      hashes and access tokens, webpush.db holds browser push subscriptions,
#      and server.yml may hold SMTP/upstream credentials. The folders are set
#      to 0700, the files to 0600, and umask 077 keeps anything created later
#      private. S11 in the review report.
#
#   2. It hands over to `ntfy serve` with exec(), so ntfy is PID 1 and gets
#      SIGTERM directly from `docker stop` (no shell in between, clean exit).
#
# Attachments: upstream refuses to start when attachment-cache-dir is set
# without base-url, and the NAS address is not known inside the container, so
# this package leaves both unset and attachments are off. To enable them, put
# both keys in /Volume1/DockerAppData/ntfydocker/config/server.yml and restart:
#
#     base-url: "http://192.168.1.10:8034"     # your NAS address
#     attachment-cache-dir: "/var/cache/ntfy/attachments"
#
# MAINTAINERS: this file is embedded into docker-compose.yml by
# scripts/build.sh, which indents it and escapes every dollar sign. Edit THIS
# file only, and never write a doubled dollar sign here.
# ===========================================================================
set -u
set -e

umask 077

for d in /var/cache/ntfy /etc/ntfy /var/lib/ntfy; do
    if [ -d "$d" ]; then
        chmod 700 "$d" 2>/dev/null || true
    fi
done

for f in /var/cache/ntfy/cache.db \
         /var/cache/ntfy/cache.db-wal \
         /var/cache/ntfy/cache.db-shm \
         /var/lib/ntfy/user.db \
         /var/lib/ntfy/user.db-wal \
         /var/lib/ntfy/user.db-shm \
         /var/lib/ntfy/webpush.db \
         /var/lib/ntfy/webpush.db-wal \
         /var/lib/ntfy/webpush.db-shm \
         /etc/ntfy/server.yml; do
    if [ -f "$f" ]; then
        chmod 600 "$f" 2>/dev/null || true
    fi
done

exec ntfy serve
