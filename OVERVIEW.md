# Deploy and Host Grounded Docs MCP Server on Railway

Grounded Docs MCP Server is an open-source documentation index for AI coding assistants, and an open alternative to Context7. It fetches documentation from websites, GitHub repositories, npm, PyPI and archives, stores each library version separately, and serves version-aware search over the Model Context Protocol (MCP) and a web UI.

## About Hosting Grounded Docs MCP Server

This template runs the official `ghcr.io/arabold/docs-mcp-server` image (version 3.5.0, pinned by digest), built from a public GitHub repo so Railway can tell you about updates. One service serves the web UI and the MCP endpoint, and its SQLite index and settings sit on a Railway volume at `/data`. Upstream leaves the web UI open, and its own MCP auth needs an outside OAuth provider. So a small Caddy proxy in the same container asks for a generated password on the web UI and its API, and a generated bearer token on `/mcp`. Search works with full-text matching out of the box. Add an OpenAI-compatible key to turn on vector search.

## Common Use Cases

* Give Claude Code, Cursor, VS Code, Windsurf or any MCP client up-to-date documentation for the exact library versions your project uses
* Index internal or niche documentation (websites, GitHub repos, npm and PyPI packages, ZIP or TAR archives) once and share it with your whole team
* Replace a hosted documentation service such as Context7 with one you run and control yourself

## Dependencies for Grounded Docs MCP Server Hosting

* One Railway service built from the template repo (the app with a Caddy auth proxy in front)
* One Railway volume at `/data` for the index database and `config.yaml`

### Deployment Dependencies

* Upstream project: https://github.com/arabold/docs-mcp-server
* Release notes: https://github.com/arabold/docs-mcp-server/releases
* Template repo: https://github.com/aalfath/grounded-docs-mcp-server-railway-template
* Optional, for vector search: an OpenAI API key (https://platform.openai.com/api-keys) or any OpenAI-compatible embeddings endpoint

### Implementation Details

**After deploy.** Open the service's Railway URL. Your browser asks for a username and password: the username is `admin`, and the password is the `WEB_PASSWORD` variable on the service (Variables tab). Choose **Add library** to index your first documentation.

**Connect your AI client.** The MCP endpoint is `https://YOUR-DOMAIN/mcp` and needs the `MCP_AUTH_TOKEN` variable as a bearer token. For Claude Code:

```bash
claude mcp add --transport http grounded-docs https://YOUR-DOMAIN/mcp --header "Authorization: Bearer YOUR-MCP_AUTH_TOKEN"
```

Most other clients (Cursor, VS Code, Windsurf) accept:

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

**Variables.**

| Variable | Default | What it does |
|---|---|---|
| `WEB_USERNAME` | `admin` | Username for the web UI |
| `WEB_PASSWORD` | generated | Password for the web UI and its API |
| `MCP_AUTH_TOKEN` | generated | Bearer token MCP clients send on `/mcp` |
| `OPENAI_API_KEY` | empty | Optional. Turns on vector search with `text-embedding-3-small` |
| `OPENAI_API_BASE` | empty | Optional. Base URL of an OpenAI-compatible embeddings API (Ollama, LM Studio, OpenRouter) |
| `DOCS_MCP_EMBEDDING_MODEL` | empty | Optional. Embedding model, for example `text-embedding-3-small` or `gemini:gemini-embedding-001` |

Set the embedding key before you index anything: pages indexed without a model get no vectors until you scrape them again with "replace". Changing the model later stops the server until you set `DOCS_MCP_ACCEPT_MODEL_CHANGE=true` once (it deletes stored vectors), then remove it again.

**Memory.** The service runs in 0.5 GB of RAM: it idles at about 270 MB, and below 1.5 GB the template fetches one page at a time, so the headless Chromium it uses for JavaScript-heavy sites stays inside the limit. With more RAM it fetches 3 pages at a time. Telemetry is off by default (`DOCS_MCP_TELEMETRY=false`).

**Updates.** The template builds from `aalfath/grounded-docs-mcp-server-railway-template`. When a new upstream release ships, the version bump is merged there and Railway shows an "update available" notice on your project. Read `CHANGELOG.md` in the repo before you apply it. Your index on the volume is kept and migrated on start.

## Why Deploy Grounded Docs MCP Server on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Grounded Docs MCP Server on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
