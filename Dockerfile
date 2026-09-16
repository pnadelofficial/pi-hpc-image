# Pi coding agent + preloaded packages, built for use on an HPC cluster
# (Docker locally -> Apptainer/Singularity on the cluster).
FROM node:22-bookworm-slim

# Pin versions here for reproducible builds, e.g. PI_WEB_ACCESS=@0.29.0
ARG PI_VERSION=latest
ARG FEYNMAN_VERSION=latest
ARG PI_WEB_ACCESS=
ARG PI_SUBAGENTS=
ARG PI_SANDBOX=

# System deps:
#  - git, ripgrep, fd: general agent tooling
#  - bubblewrap, socat, ripgrep: required by pi-sandbox's Linux sandbox runtime
#  - ffmpeg, yt-dlp: optional video frame extraction for pi-web-access
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git openssh-client \
        ripgrep fd-find jq less procps tmux \
        bubblewrap socat \
        ffmpeg python3 python3-pip \
    && pip3 install --no-cache-dir --break-system-packages yt-dlp \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

ENV NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false

# Pi itself (npm install is required for pi-subagents background children)
# and Feynman, which is a separate research CLI built on Pi.
RUN npm install -g \
        @earendil-works/pi-coding-agent@${PI_VERSION} \
        @companion-ai/feynman@${FEYNMAN_VERSION} \
    && npm cache clean --force

# Install Pi packages into a "skeleton" agent dir inside the image.
# At runtime the entrypoint copies this into a writable location, because
# Apptainer images are read-only and your cluster $HOME is bind-mounted over
# the image's home directory.
RUN mkdir -p /opt/pi-skel/agent \
    && export PI_CODING_AGENT_DIR=/opt/pi-skel/agent \
    && pi install "npm:pi-web-access${PI_WEB_ACCESS}" \
    && pi install "npm:pi-subagents${PI_SUBAGENTS}" \
    && pi install "npm:pi-sandbox${PI_SANDBOX}" \
    && pi list \
    && npm cache clean --force

COPY config/sandbox.json config/web-search.json /opt/pi-skel/agent/
COPY entrypoint.sh /usr/local/bin/pi-entrypoint
RUN chmod 755 /usr/local/bin/pi-entrypoint && chmod -R a+rX /opt/pi-skel

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/pi-entrypoint"]
CMD ["pi"]