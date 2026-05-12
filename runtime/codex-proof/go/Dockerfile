FROM golang:1.22-bookworm

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    nodejs \
    npm \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Codex installation and authentication preflight are added in later slices.
CMD ["sh", "-lc", "echo 'codex proof go runtime placeholder ready'"]
