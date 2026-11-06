<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/lightcraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.lightcraft.png" width="128" height="128" alt="LightCraft application icon">
</p>

<h1 align="center">LightCraft Web — Docker Image</h1>
<p align="center">
  A community-maintained Docker image for
  <a href="https://github.com/storytold/lightcraft">LightCraft</a>,
  bringing its WebAssembly-based non-destructive photo editor to a self-hosted web interface.
  <br>
  Build automation and image publication to GitHub Container Registry (GHCR).
</p>
<p align="center">
  <a href="https://github.com/MikaPST/lightcraft-web/actions/workflows/publish-image.yml">
    <img src="https://github.com/MikaPST/lightcraft-web/actions/workflows/publish-image.yml/badge.svg" alt="Build and publish LightCraft Web">
  </a>
  <a href="https://github.com/MikaPST/lightcraft-web/releases/latest">
    <img src="https://img.shields.io/github/v/release/MikaPST/lightcraft-web?label=Release&logo=github&color=blue" alt="Latest Release">
  </a>
  <a href="https://github.com/MikaPST/lightcraft-web/pkgs/container/lightcraft-web">
    <img src="https://ghcr-badge.egpl.dev/mikapst/lightcraft-web/latest_tag?trim=major&label=GHCR" alt="GHCR image tag">
  </a>
  <a href="docker-compose.yml">
    <img src="https://img.shields.io/badge/Docker%20Compose-ready-2496ED?logo=docker&logoColor=white" alt="Docker Compose configuration">
  </a>
</p>

---

## Why this repository?

The upstream LightCraft project provides a WebAssembly build that can be served as a static website. This repository automates building that web application from upstream source and packages the generated files into a lightweight NGINX-based Docker image.

The goals are to:

- Publish a matching GitHub Release only after the Docker build and push succeed.
- Build the WebAssembly application from official release tags in [storytold/lightcraft](https://github.com/storytold/lightcraft).
- Include the shared font assets from [storytold/craft-fonts](https://github.com/storytold/craft-fonts).
- Check weekly for new official releases and publish a versioned image to GHCR.
- Provide Docker deployment for Unraid Community Applications.
- Keep this packaging project separate from the upstream LightCraft source code.

This is an independent community packaging project. It is **not an official LightCraft release** and is not affiliated with or endorsed by the LightCraft or ArtCraft maintainers.

## How it works

LightCraft's web application runs in the browser using WebAssembly and WebGL2. The container serves the compiled static web files through NGINX; it does not run a remote desktop or a server-side photo-processing service.

- **Browser-based editor:** use LightCraft through a modern browser with WebGL2 support.
- **Local photo library:** photos are imported through the browser and stored in browser-managed storage (OPFS / IndexedDB), not in a Docker volume.
- **Local processing:** image decoding, development and rendering run in the browser using the same Rust engine as the desktop application.
- **Web Workers:** rendering jobs can run in dedicated browser workers, with a main-thread fallback.
- **Self-hosted delivery:** the container hosts the application files. Each browser/device has its own browser storage and library.

**Important:** browser storage belongs to the browser profile on a particular device. It is not shared between users or browsers, and it is not a server-side backup. Use LightCraft's library backup and restore features and keep independent copies of original photos. Review the upstream documentation for current data-safety limitations before relying on the web app for important work.

## Docker image

The published image is:

```text
ghcr.io/mikapst/lightcraft-web:latest
```

Each official upstream release is also published under its exact version tag, for example:

```text
ghcr.io/mikapst/lightcraft-web:vX.Y.Z
```

Use a versioned tag if you want to keep a deployment on a specific release. The `latest` tag updates when an image is published.

### Quick start with Docker Compose

A `docker-compose.yml` file is provided at the repository root:

```yaml
services:
  lightcraft-web:
    image: ghcr.io/mikapst/lightcraft-web:latest
    container_name: lightcraft-web
    restart: unless-stopped
    ports:
      - "8080:8080"
```

Start LightCraft Web from the repository directory:

```bash
docker compose up -d
```

Then open:

```text
http://YOUR_SERVER_IP:8080
```

Replace `YOUR_SERVER_IP` with the IP address or hostname of your server. On the same computer, use `http://localhost:8080`.

### Run directly with Docker

```bash
docker run -d \
  --name lightcraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/lightcraft-web:latest
```

### Useful commands

```bash
# View logs
docker compose logs -f

# Pull the latest image and recreate the container
docker compose pull
docker compose up -d

# Stop and remove the container
docker compose down
```

No `.env` file or persistent Docker volume is required for the default configuration. The host port is `8080`; to use a different host port, change the left-hand side of the port mapping, for example `8081:8080`.

### Reverse proxy and browser requirements

The NGINX configuration:

- serves `.wasm` files with the `application/wasm` MIME type;
- serves the precompressed gzip assets generated by the upstream build when the browser supports gzip;
- uses `Cache-Control: no-cache` because the upstream bundle uses stable filenames between builds.

The upstream documentation describes the COOP, COEP and CORP response headers as optional for the current web build. They are not required by this image's default NGINX configuration.

LightCraft requires an HTTP(S) origin; it cannot be opened directly from `file://`. `localhost` and `127.0.0.1` are treated as secure origins by browsers. If you expose the application outside your local network, use HTTPS through a reverse proxy such as Traefik and avoid exposing plain HTTP directly to the public Internet.

The web application uses WebGL2. Browser and GPU compatibility, available memory and the size/format of imported photos affect performance.

## Automated builds

GitHub Actions checks the official [LightCraft releases](https://github.com/storytold/lightcraft/releases), builds the WebAssembly application from the selected upstream tag and publishes the image to GHCR.

| Trigger | Behaviour |
|---|---|
| Weekly schedule | Checks the latest official LightCraft release and builds it if it has not already been published here |
| Manual workflow dispatch | Builds the latest official release, or a specified `upstream_tag` |
| Force rebuild | Rebuilds an already published version with `force_rebuild: true` |
| Changes to packaging files on `main` | Rebuilds the current official upstream release with the updated workflow |

### Published tags

- `latest` — the latest successfully published image (mutable tag).
- `<upstream-version>` — the exact official upstream tag, for example `vX.Y.Z`.
- `upstream-<commit>` — the upstream source commit used for the image (first 12 hexadecimal characters).

The image targets both `linux/amd64` and `linux/arm64`. The workflow checks out **the official upstream release tag**, rather than compiling `main` as the versioned source.

### GitHub Releases

After a successful Docker build and GHCR push, the workflow creates or updates a [GitHub Release](https://github.com/MikaPST/lightcraft-web/releases) matching the upstream tag. It includes the upstream release notes, source link and commit, Docker tags, supported architectures and (when available) the published image digest.

The Release badge at the top of this README updates automatically. Scheduled runs skip versions already released here. You can force a rebuild from **Actions → Build and publish LightCraft Web → Run workflow**.

> [!IMPORTANT]
> A GitHub Release is created only after the Docker image has been successfully published. The `latest` tag may change after a rebuild; pin a versioned image tag for a stable deployment. Auxiliary source repositories (for example `craft-fonts`) may be checked out separately and are not necessarily pinned to the upstream release commit.

### Build pipeline

The workflow:

1. Checks out this repository.
2. Checks out LightCraft and the shared `craft-fonts` repository.
3. Installs the Rust WebAssembly target and the exact `wasm-bindgen-cli` version required by the upstream `Cargo.lock`.
4. Runs `cargo xtask web` with `CRAFT_FONTS_DIR` pointing to the checked-out font repository.
5. Checks the generated files in `upstream/target/web-site`.
6. Packages the generated static site into an NGINX image and publishes it to GHCR.

The upstream release build creates precompressed gzip and Brotli copies. This image configures NGINX's `gzip_static` support to serve the precompressed gzip files. The standard `nginx:alpine` image used here does not include a Brotli module, so the `.br` files are retained in the site but are not served as Brotli responses by this configuration.

The workflow generates the Dockerfile and NGINX configuration during the GitHub Actions run. Separate `Dockerfile`, `nginx.conf` and `.dockerignore` files are therefore not required in this packaging repository.

The repository is primarily intended as an automated image-build and publication pipeline; the normal way to consume it is to pull the published image.

## Unraid Community Applications

This image can be deployed on Unraid.

The Unraid Community Applications template is maintained in [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps), separately from this image-build repository.

In the meantime, LightCraft Web can be deployed on Unraid using the Docker Compose configuration above or by configuring the container manually with:

- **Repository:** `ghcr.io/mikapst/lightcraft-web:latest`
- **Container port:** `8080`
- **Host port:** `8080` by default

Remember that the photo library is stored in each user's browser storage, not in the Unraid appdata directory. Removing browser data or changing browser profiles can make that library unavailable. Use the application's backup and restore functionality.
- **Template:** [lightcraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/lightcraft-web.xml)

## Upstream project

- **LightCraft source code:** [storytold/lightcraft](https://github.com/storytold/lightcraft)
- **LightCraft web build and hosting instructions:** [docs/web.md](https://github.com/storytold/lightcraft/blob/main/docs/web.md)
- **Shared font assets:** [storytold/craft-fonts](https://github.com/storytold/craft-fonts)
- **Official releases:** [LightCraft releases](https://github.com/storytold/lightcraft/releases)

The MikaPST GitHub Release tracks the upstream version but represents independent Docker packaging, not an official LightCraft distribution.

## License and attribution

LightCraft is open source and is dual-licensed under the MIT License or Apache License 2.0, at the user's option, as specified by the upstream project. The `craft-fonts` assets have their own licensing and attribution requirements; consult that repository for the applicable notices.

The license of the upstream application and its assets does not automatically determine the license of the packaging files maintained in this repository. If you want to grant reuse rights for your own workflow, Compose file and documentation, select and include a separate `LICENSE` for this repository.

LightCraft names, artwork and logos remain subject to the upstream project's trademark and usage terms.

## Disclaimer

This repository is maintained independently and is not affiliated with, sponsored by or endorsed by the LightCraft project or its maintainers.

LightCraft's web build is under active development. Review upstream release notes and data-safety documentation, keep independent backups of original photos and library data, and test updates before relying on the application for important work.
