# NOTICE — third-party components and attributions

This package (`ntfydocker`, TOS 7 Docker application) is an independent packaging by Moechz
of the upstream **ntfy** project.

## 1. Upstream application — ntfy

- Project: <https://github.com/binwiederhier/ntfy>
- Licence: **Apache-2.0** (server and client; see the upstream `LICENSE` and `NOTICE`)
- Relationship: the upstream application is used **unmodified**, inside the container image.
  No upstream source code is redistributed in this package; the package only pulls the image
  from Docker Hub.

## 2. Container image — `binwiederhier/ntfy:v2.38.1`

- Registry: Docker Hub (`binwiederhier/ntfy:v2.38.1`)
- Maintainer: the ntfy project (binwiederhier)
- The image is built by its maintainer from an Alpine base and is pulled from Docker Hub at
  install time; it is not redistributed here.

## 3. Components inside the image

The image bundles the Go ntfy server, the compiled web UI, the ntfy CLI and the Alpine
userland of its base image. Their licences are documented in the image's own package metadata
and in the upstream repository; they are shipped inside the image only and are not
redistributed as separate files by this package.

## 4. This packaging

The files authored for this package — `docker-compose.yml`, `config.ini`,
`ntfydocker.lang`, `ntfydocker.svg`, the build/verification scripts and this documentation —
are released under the **MIT** licence (see `LICENSE`).

Running the Apache-2.0 application from its official image does not make this packaging a
derivative work of it; the packaging contains no upstream code.

## 5. Trademarks

“ntfy”, “TerraMaster” and “TOS” are trademarks or registered trademarks of their respective
owners. Their use here is descriptive only. This package is **not affiliated with, sponsored
or endorsed by** the upstream project or TerraMaster.

## 6. Icon

The application icon in `src/ntfydocker.svg` is an original mark drawn for this package. It
does not reproduce the upstream logo.

## 7. Contact

Moechz — moechz@163.com — <https://github.com/Moechz/ntfy>
