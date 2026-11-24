# Grounded Docs MCP Server for Railway: the official image, with a small Caddy front
# that asks for a generated password on the web UI and a generated bearer token on MCP.
FROM caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0 AS caddy

FROM ghcr.io/arabold/docs-mcp-server:3.5.0@sha256:290580d5954755277f137a6bc4e064086d74c6d9c351f9b22fabe7c6d9ce39fa
USER root
COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY start.sh /usr/local/bin/start.sh
RUN chmod 755 /usr/local/bin/start.sh /usr/local/bin/caddy \
 && caddy version \
 && node dist/index.js --version
# Everything the app keeps (database and config.yaml) lives on the /data volume.
ENV PORT=8080 \
    DOCS_MCP_STORE_PATH=/data \
    SQLITE_TMPDIR=/data \
    XDG_CONFIG_HOME=/data/config \
    GOMAXPROCS=1 \
    GOMEMLIMIT=64MiB
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/start.sh"]
