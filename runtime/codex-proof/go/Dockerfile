FROM golang:1.22-bookworm

ENV PATH="/usr/local/go/bin:${PATH}"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    nodejs \
    npm \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g @openai/codex@0.130.0

WORKDIR /workspace

CMD ["sh", "-lc", "echo 'codex proof go runtime placeholder ready'"]
