# CI image of SolarWars 2: the Elixir toolchain for its check jobs, plus Node
# and Chromium's system packages for its Playwright end-to-end tests, so CI
# jobs don't install them on every run. Change the versions with
# scripts/bump-versions.sh, which also sets the image tag in .env.
FROM hexpm/elixir:1.20.4-erlang-29.1.2-debian-trixie-20261020

ARG NODE_VERSION=24.22.1
ARG PLAYWRIGHT_VERSION=1.64.1

# Hex and rebar live here instead of ~/.mix, so jobs that point HEX_HOME at
# their cache directory still find them
ENV MIX_HOME=/opt/mix

# a C toolchain for NIFs (cmake: lazy_html), git for GitHub-hosted deps,
# curl and xz for the Node download
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		ca-certificates \
		cmake \
		curl \
		git \
		xz-utils \
	&& rm -rf /var/lib/apt/lists/*

# Node from nodejs.org, checked against its published SHA-256 sums
RUN arch="$(dpkg --print-architecture | sed 's/amd64/x64/')" \
	&& file="node-v${NODE_VERSION}-linux-${arch}.tar.xz" \
	&& cd /tmp \
	&& curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/${file}" \
	&& curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" | grep " ${file}\$" | sha256sum -c - \
	&& tar -xJf "${file}" -C /usr/local --strip-components=1 --no-same-owner \
	&& rm "${file}" \
	&& node --version && npm --version

# only the system packages; the browser itself is cached by the e2e jobs
RUN npx -y "playwright@${PLAYWRIGHT_VERSION}" install-deps chromium \
	&& rm -rf /var/lib/apt/lists/* /root/.npm

RUN mix local.hex --force \
	&& mix local.rebar --force
