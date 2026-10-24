#!/usr/bin/env bash
# Changes the tool versions of the solarwars-pipeline image: the Dockerfile,
# the image tag in .env (elixir<x>-otp<y>-node<z>-pw<w>) and the README.
#
#   scripts/bump-versions.sh --node 24.23.0 --playwright 1.65.0
#   scripts/bump-versions.sh --elixir 1.20.5-erlang-29.1.3-debian-trixie-20261120
#
# Exits 1 with the usage on unknown or missing options.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKERFILE="$ROOT/images/solarwars-pipeline/Dockerfile"
ENV_FILE="$ROOT/.env"
README="$ROOT/README.md"

# BSD sed (macOS) requires an explicit empty-string argument to -i; GNU sed does not.
sedi() {
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

usage() {
  printf 'Usage: %s [options]\n\n' "$(basename "$0")"
  printf 'Options:\n'
  printf '  --elixir <tag>       hexpm/elixir image tag  (e.g. 1.20.5-erlang-29.1.3-debian-trixie-20261120)\n'
  printf '  --node <version>     Node version  (e.g. 24.23.0)\n'
  printf '  --playwright <v>     Playwright version  (e.g. 1.65.0)\n'
  exit 1
}

# Prints the value of `ARG <name>=<value>` in the Dockerfile.
# Example: dockerfile_arg NODE_VERSION -> 24.22.1
dockerfile_arg() {
  sed -n "s/^ARG $1=//p" "$DOCKERFILE"
}

ELIXIR_TAG=""
NODE_VER=""
PLAYWRIGHT_VER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --elixir)     ELIXIR_TAG="$2";     shift 2 ;;
    --node)       NODE_VER="$2";       shift 2 ;;
    --playwright) PLAYWRIGHT_VER="$2"; shift 2 ;;
    -h|--help)    usage ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage ;;
  esac
done

[[ -z "$ELIXIR_TAG" && -z "$NODE_VER" && -z "$PLAYWRIGHT_VER" ]] && usage

if [[ -n "$ELIXIR_TAG" ]]; then
  sedi "s|^FROM hexpm/elixir:.*|FROM hexpm/elixir:$ELIXIR_TAG|" "$DOCKERFILE"
  sedi "s|hexpm/elixir:[^\`]*\`|hexpm/elixir:$ELIXIR_TAG\`|" "$README"
  printf 'Dockerfile + README: base image → hexpm/elixir:%s\n' "$ELIXIR_TAG"
fi

if [[ -n "$NODE_VER" ]]; then
  sedi "s|^ARG NODE_VERSION=.*|ARG NODE_VERSION=$NODE_VER|" "$DOCKERFILE"
  sedi "s|Node [0-9][0-9.]*|Node $NODE_VER|" "$README"
  printf 'Dockerfile + README: Node → %s\n' "$NODE_VER"
fi

if [[ -n "$PLAYWRIGHT_VER" ]]; then
  sedi "s|^ARG PLAYWRIGHT_VERSION=.*|ARG PLAYWRIGHT_VERSION=$PLAYWRIGHT_VER|" "$DOCKERFILE"
  sedi "s|Playwright [0-9][0-9.]*|Playwright $PLAYWRIGHT_VER|" "$README"
  printf 'Dockerfile + README: Playwright → %s\n' "$PLAYWRIGHT_VER"
fi

# hexpm/elixir:1.20.4-erlang-29.1.2-debian-... -> 1.20.4 and 29.1.2
base="$(sed -n 's|^FROM hexpm/elixir:||p' "$DOCKERFILE")"
elixir="${base%%-erlang-*}"
otp="${base#*-erlang-}"
otp="${otp%%-*}"
tag="elixir$elixir-otp$otp-node$(dockerfile_arg NODE_VERSION)-pw$(dockerfile_arg PLAYWRIGHT_VERSION)"
sedi "s|^DOCKER_HUB_TAG=.*|DOCKER_HUB_TAG=\"$tag\"|" "$ENV_FILE"
sedi "s|solarwars-pipeline:elixir[^\`]*\`|solarwars-pipeline:$tag\`|g" "$README"
printf '.env + README: tag → %s\n' "$tag"
