FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends bash curl jq fzf ca-certificates \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /work
ENTRYPOINT ["bash", "/work/harness.sh"]
