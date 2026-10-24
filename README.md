# solarwars-pipeline

CI image for SolarWars 2, a browser real-time strategy game built with Elixir/Phoenix and a TypeScript client. Its check and end-to-end test jobs run in this image, so they don't have to install the build tools, Node and the browser's system packages on every run.

The image is built by GitHub Actions and published on Docker Hub as [`voidptrorg/solarwars-pipeline`](https://hub.docker.com/r/voidptrorg/solarwars-pipeline).

## Image

`voidptrorg/solarwars-pipeline:elixir1.20.4-otp29.1.2-node24.22.1-pw1.64.1`, for `linux/amd64` and `linux/arm64`.

The tag names the versions inside. There is no `latest` tag, so pin an exact tag.

Included:

- the base image `hexpm/elixir:1.20.4-erlang-29.1.2-debian-trixie-20261020`;
- `build-essential`, `cmake` and `git` for NIFs and Git dependencies, plus `curl`, `xz-utils` and `ca-certificates`;
- Node 24.22.1 from nodejs.org, checked against its published SHA-256 sums;
- the system packages that Playwright 1.64.1's Chromium needs (`playwright install-deps chromium`);
- Hex and rebar, in `MIX_HOME=/opt/mix`, so jobs can point `HEX_HOME` at their own cache directory.

The Chromium browser itself is not included. Install it in the job with `npx playwright install chromium` and cache it there (`PLAYWRIGHT_BROWSERS_PATH`), so Playwright patch releases don't need a new image.

## Build and publish

[.github/workflows/docker.yml](.github/workflows/docker.yml) builds every directory under `images/` on each push to `main` that changes `images/**`, `.env` or the workflow. It can also be started by hand (_Actions → Docker → Run workflow_).

- **Tag and platforms:** read from [.env](.env): `DOCKER_HUB_ORG`, `DOCKER_HUB_TAG` and `DOCKER_BUILD_PLATFORM`.
- **Push:** uses the repository secrets `DOCKER_HUB_USERNAME` and `DOCKER_HUB_TOKEN`.

### Changing versions

```sh
scripts/bump-versions.sh --node 24.23.0 --playwright 1.65.0
scripts/bump-versions.sh --elixir 1.20.5-erlang-29.1.3-debian-trixie-20261120
```

The script updates the Dockerfile, the tag in `.env` and this README. Pushing the change to `main` publishes the new tag.

A rebuild with unchanged versions overwrites the existing tag, for example after a fix in the Dockerfile.

### Local build and manual publish

```sh
docker buildx build --platform linux/arm64 --load -t solarwars-pipeline:test images/solarwars-pipeline

# manual publish, both platforms (one-time: docker buildx create --name multiarch-builder --driver docker-container --use)
set -a && . ./.env && set +a
docker buildx build --builder multiarch-builder --platform "$DOCKER_BUILD_PLATFORM" \
  -t "$DOCKER_HUB_ORG/solarwars-pipeline:$DOCKER_HUB_TAG" --push images/solarwars-pipeline
docker buildx imagetools inspect "$DOCKER_HUB_ORG/solarwars-pipeline:$DOCKER_HUB_TAG"
```

Both `linux/amd64` and `linux/arm64` must be listed.

A quick check of a local build:

```sh
docker run --rm solarwars-pipeline:test sh -c 'elixir --version && node --version && mix hex.info'
```

## License

[MIT](LICENSE)
