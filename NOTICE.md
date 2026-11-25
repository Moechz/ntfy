# NOTICE — third-party components and attributions

This package (`ntfydocker`, TOS 7 Docker application) is an independent packaging by Moechz
of the upstream **ntfy** project. It is not affiliated with, sponsored or endorsed by the
upstream project or TerraMaster.

## 1. Upstream application — ntfy

- Project: <https://github.com/binwiederhier/ntfy>
- Version packaged: **2.38.2** (released 2026-11-24)
- Licence: **Apache-2.0 OR GPL-2.0** — upstream is dual-licensed (see the upstream `LICENSE`
  and `LICENSE.GPLv2`, and the “License” section of the upstream README). This package relies
  on the **Apache-2.0** option. The image bundles the server (Apache-2.0 option) and the
  compiled web UI; both are used unmodified inside the container image.
- Relationship: the upstream application is used **unmodified**, inside the container image.
  No upstream source code is redistributed in this package; the package only pulls the image
  from Docker Hub. Users who prefer the GPLv2 option can obtain the corresponding source from
  the upstream repository and rebuild the image.

## 2. Container image — `binwiederhier/ntfy:v2.38.2`

- Registry: Docker Hub (`binwiederhier/ntfy:v2.38.2`)
- Maintainer: the ntfy project (binwiederhier), image author Philipp C. Heckel
- Multi-arch manifest list (OCI/Docker index):
  `sha256:ca35419d29a834824db2440fa9320897fbe40b026c5fc2360c76ed3501b5e716`
  - `linux/amd64`: `sha256:cc40cb7437494639bbea89f13647c47765496dc8c579822b6239bca6cfd238ed`
  - `linux/arm64`: `sha256:3783af9a1e0ef6a7aea9ee7297258b97efff94fde0df20546e60ece9d1ab99ba`
- The image is built by its maintainer on an Alpine base and is pulled from Docker Hub at
  install time; it is not redistributed here. The image labels declare
  `org.opencontainers.image.licenses = Apache-2.0, GPL-2.0`.

## 3. Components inside the image

The image bundles the Go ntfy server, the compiled web UI and the Alpine userland of its base
image. The upstream README lists the main third-party components, among them React (MIT),
Material UI (MIT), Roboto (Apache-2.0), `urfave/cli` (MIT) and notification sounds under their
own licences. Their licence texts ship inside the image and in the upstream repository; they
are not redistributed as separate files by this package.

## 4. This packaging

The files authored for this package — `docker-compose.yml`, `config.ini`, `ntfydocker.lang`,
`ntfydocker.svg`, `src/entrypoint.sh`, the build/verification scripts, `README.md`,
`PRIVACY.md`, `CHANGELOG.md` and this NOTICE — are released under the **MIT** licence (see
`LICENSE`).

Running the Apache-2.0/GPL-2.0 application from its official image does not make this
packaging a derivative work of it; the packaging contains no upstream source code.

## 5. Trademarks

“ntfy”, “TerraMaster” and “TOS” are trademarks or registered trademarks of their respective
owners. Their use here is descriptive only. This package is **not affiliated with, sponsored
or endorsed by** the upstream project or TerraMaster.

## 6. Icon

The application icon in `src/ntfydocker.svg` is an original mark drawn for this package. It
does not reproduce the upstream logo.

## 7. Contact

Moechz — moechz@163.com — <https://github.com/Moechz/ntfy>
