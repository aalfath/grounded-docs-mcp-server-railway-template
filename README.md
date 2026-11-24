[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/grounded-docs-mcp-server?utm_medium=integration&utm_source=button&utm_campaign=grounded-docs-mcp-server)

# Grounded Docs MCP Server on Railway

One-click Railway template for [Grounded Docs MCP Server](https://github.com/arabold/docs-mcp-server) (`arabold/docs-mcp-server`, MIT), a self-hosted documentation index for AI coding assistants and an open alternative to Context7. It fetches documentation from websites, GitHub repositories, npm, PyPI and archives, and serves version-aware search over MCP and a web UI.

## What it deploys

| Service | What it does |
|---|---|
| **Grounded Docs** (built from this repo) | The official `ghcr.io/arabold/docs-mcp-server:3.5.0` image (pinned by digest) on loopback, with Caddy 2.11.9 in front on `$PORT`. Caddy asks for a generated password on the web UI and its API, and a generated bearer token on `/mcp`. `/healthz` answers without login. Index database and `config.yaml` live on a volume at `/data`. |

Upstream's own authentication covers only `/mcp` and needs an outside OAuth provider; the web UI and API have none. That is why this template puts the Caddy front in the same container.

## Variables

| Variable | Default | What it does |
|---|---|---|
| `WEB_USERNAME` | `admin` | Username for the web UI |
| `WEB_PASSWORD` | `${{secret(24)}}` | Password for the web UI and its API |
| `MCP_AUTH_TOKEN` | `${{secret(40)}}` | Bearer token MCP clients send on `/mcp` |
| `OPENAI_API_KEY` | empty | Optional: turns on vector search (`text-embedding-3-small` by default) |
| `OPENAI_API_BASE` | empty | Optional: OpenAI-compatible embeddings base URL (Ollama, LM Studio, OpenRouter) |
| `DOCS_MCP_EMBEDDING_MODEL` | empty | Optional: embedding model, e.g. `gemini:gemini-embedding-001` |
| `PORT` | `8080` | Port Caddy listens on |

Any other upstream setting can be added as a `DOCS_MCP_*` variable ([configuration reference](https://github.com/arabold/docs-mcp-server/blob/v3.5.0/docs/setup/configuration.md)). The template sets `DOCS_MCP_SERVER_PUBLIC_URL` from the Railway domain and turns telemetry off (`DOCS_MCP_TELEMETRY=false`) unless you set them.

## After deploy

1. Open the service URL. The browser asks for `admin` and the `WEB_PASSWORD` from the service's Variables tab.
2. Choose **Add library** and index your first docs.
3. Connect your client to `https://YOUR-DOMAIN/mcp` with the header `Authorization: Bearer <MCP_AUTH_TOKEN>`, for example:

```bash
claude mcp add --transport http grounded-docs https://YOUR-DOMAIN/mcp --header "Authorization: Bearer YOUR-MCP_AUTH_TOKEN"
```

```json
{
  "mcpServers": {
    "grounded-docs": {
      "url": "https://YOUR-DOMAIN/mcp",
      "headers": { "Authorization": "Bearer YOUR-MCP_AUTH_TOKEN" }
    }
  }
}
```

Set the embedding key before you index: pages indexed without a model get no vectors until you scrape them again with "replace". Changing the model later stops the server until you set `DOCS_MCP_ACCEPT_MODEL_CHANGE=true` once (this deletes stored vectors); remove it afterwards.

## Memory

It runs on Railway's 0.5 GB plan. Idle use is about 270 MB. Below 1.5 GB the start script fetches one page at a time, caps Node's heap and runs Chromium (used for JavaScript-heavy sites) in a low-memory mode. Chromium is also the kernel's first choice when memory runs out, so a very heavy page loses only its render (it is indexed as fetched) and the server stays up. Tested: 60 pages of react.dev at 0.5 GB with no OOM kill. With 1 GB or more you get upstream's default of 3 pages at a time.

## Updates

Railway notifies deployers when this repo's `main` changes. Each version bump comes with a `CHANGELOG.md` entry, breaking changes first. The index on `/data` is kept, and upstream migrates it on start.

## Licence

The template files are MIT. Grounded Docs MCP Server is MIT, © Andre Rabold.
