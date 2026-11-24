# Changelog

## 3.5.0 (2026-11-24)

First release of the template.

- Grounded Docs MCP Server `ghcr.io/arabold/docs-mcp-server:3.5.0@sha256:290580d5954755277f137a6bc4e064086d74c6d9c351f9b22fabe7c6d9ce39fa`.
- Caddy `2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0` in front: basic auth on the web UI and API, bearer token on `/mcp`, `/healthz` for Railway.
- Data and config on the `/data` volume; telemetry off by default; low-memory scraping below 1.5 GB.
