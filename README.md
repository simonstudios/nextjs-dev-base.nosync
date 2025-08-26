# Next.js Development Base Image

A production-ready Next.js development base image optimized for VS Code devcontainers and GitHub Codespaces.

## 🚀 Features

- **Node.js 22** (bookworm-slim base)
- **Pre-installed CLI tools**:
  - Vercel CLI
  - Claude Code
  - OpenAI Codex
  - MCP helpers: `mcp-remote`, `mongodb-mcp-server` (for faster first-run)
- **Volume permission management** for seamless file sharing
- **Optimized for devcontainers** and Codespaces
- **Multi-architecture support** (AMD64, ARM64)
- **zsh + passwordless sudo** for the `node` user (Codespaces-friendly)
- **Preinstalled CLIs**: `vercel`, `claude`, `codex` available on PATH

### Privilege Model
- Runs as non-root (`node`) for day-to-day tasks.
- Installs `sudo` for optional escalation. Passwordless sudo is disabled by default; enable by setting `ENABLE_PASSWORDLESS_SUDO=1` (e.g., via devcontainer `containerEnv`).
- To enable passwordless sudo in a project:
  - Add to devcontainer.json: `"containerEnv": { "ENABLE_PASSWORDLESS_SUDO": "1" }`.

## 📦 Available Tags

- `ghcr.io/yourusername/nextjs-dev-base:latest` - Latest stable
- `ghcr.io/yourusername/nextjs-dev-base:v1.0.0` - Specific version
- `ghcr.io/yourusername/nextjs-dev-base:node-22` - Node.js 22 based

## 🛠️ Usage

### Basic Project Dockerfile

```dockerfile
FROM ghcr.io/yourusername/nextjs-dev-base:latest

# Copy package files
COPY package*.json ./

# Install project dependencies
RUN npm ci --legacy-peer-deps

# Copy project files (if needed at build time)
# COPY . .

# Default: base image keeps container alive; run your dev command in compose/devcontainer
```

### Docker Compose

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
      - "1455:1455"  # Codex OAuth
    environment:
      NODE_ENV: development
      HOST: 0.0.0.0
    volumes:
      - .:/app
      - /app/node_modules
      # CLI tool persistence
      - cli_cache:/home/node/.npm-global
      - vercel_home:/home/node/.vercel
      - codex_home:/home/node/.codex

volumes:
  cli_cache:
  vercel_home:
  codex_home:
```

### VS Code devcontainer.json

```json
{
  "name": "My Next.js App",
  "dockerComposeFile": "docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/app",
  "remoteUser": "node",
  "forwardPorts": [3000, 1455],
  "features": {
    "ghcr.io/devcontainers/features/github-cli:1": {}
  }
}
```

## ⚙️ Configuration

### Build Args (image build-time)

- `SKIP_CLI_INSTALL` (default: `false`) — Skip installing CLIs during build when set to `true`.
- `VERCEL_CLI_VERSION` (default: `latest`) — Pin Vercel CLI version (e.g., `33.0.0`).
- `CLAUDE_CODE_VERSION` (default: `latest`) — Pin Claude Code CLI version.
- `CODEX_CLI_VERSION` (default: `latest`) — Pin Codex CLI version.
- `MCP_REMOTE_VERSION` (default: `latest`) — Pin mcp-remote helper version.
- `MONGODB_MCP_SERVER_VERSION` (default: `latest`) — Pin MongoDB MCP server version.

Example:

```bash
docker build \
  --build-arg SKIP_CLI_INSTALL=false \
  --build-arg VERCEL_CLI_VERSION=latest \
  --build-arg CLAUDE_CODE_VERSION=latest \
  --build-arg CODEX_CLI_VERSION=latest \
  -t nextjs-dev-base .
```

### Volume Mounts

The image expects these volumes for persistence:

- `/home/node/.npm-global` - CLI tools cache
- `/home/node/.vercel` - Vercel authentication
- `/home/node/.codex` - Codex configuration
- `/home/node/.config` - General CLI configs
- `/home/node/.cache` - CLI caches
  
Note: Some projects may bind-mount these from a workspace-managed folder (e.g., `.devcontainer/data/*`).

## 🔧 Development

### Building locally

```bash
docker build -t nextjs-dev-base .
```

### Testing

```bash
docker run --rm -it nextjs-dev-base bash
```

## 📋 Project Migration Guide

### From existing setup:

1. **Replace your current Dockerfile.dev**:
   ```dockerfile
   FROM ghcr.io/yourusername/nextjs-dev-base:latest
   COPY package*.json ./
   RUN npm ci --legacy-peer-deps
   ```

2. **Keep your docker-compose.yml volumes** (they're still needed)

3. **Simplify your devcontainer.json** (remove complex entrypoint overrides)

### Benefits after migration:

- ✅ Faster builds (CLI tools pre-installed)
- ✅ Consistent environment across projects  
- ✅ Easy to maintain and update
- ✅ Smaller project-specific Dockerfiles

## 🧭 New Project Setup (Codespaces + Local)

Bring a new Next.js project online using this base image with secure, repeatable settings.

### 1) Files to add in your project

- `Dockerfile.dev`
  ```dockerfile
  FROM ghcr.io/yourusername/nextjs-dev-base:node-22

  ARG PUPPETEER_SKIP_DOWNLOAD=1
  ENV PUPPETEER_SKIP_DOWNLOAD=${PUPPETEER_SKIP_DOWNLOAD}

  WORKDIR /app
  COPY --chown=node:node package*.json ./
  USER node
  RUN npm ci --legacy-peer-deps --no-fund --no-audit && npm cache clean --force
  USER root
  ```

- `docker-compose.yml`
  ```yaml
  services:
    app:
      build:
        context: .
        dockerfile: Dockerfile.dev
        args:
          PUPPETEER_SKIP_DOWNLOAD: "1"
      init: true
      ports:
        - "3000:3000"
        - "1455:1455"
      environment:
        NODE_ENV: development
        HOST: 0.0.0.0
      volumes:
        - .:/app
        - /app/node_modules
        - ./.devcontainer/data/vercel:/home/node/.vercel
        - ./.devcontainer/data/codex:/home/node/.codex
        - ./.devcontainer/data/config:/home/node/.config
        - ./.devcontainer/data/cache:/home/node/.cache
  ```

- `.devcontainer/devcontainer.json`
  ```jsonc
  {
    "name": "My App Dev",
    "dockerComposeFile": "../docker-compose.yml",
    "service": "app",
    "workspaceFolder": "/app",
    "overrideCommand": true,
    "remoteUser": "node",
    "forwardPorts": [3000, 1455],
    "portsAttributes": {
      "3000": { "label": "Next.js App", "onAutoForward": "notify" },
      "1455": { "label": "Codex Auth", "onAutoForward": "silent" }
    },
    "otherPortsAttributes": { "onAutoForward": "ignore" },
    "customizations": {
      "vscode": {
        "settings": {
          "typescript.tsdk": "node_modules/typescript/lib",
          "terminal.integrated.defaultProfile.linux": "zsh"
        }
      }
    },
    "features": { "ghcr.io/devcontainers/features/github-cli:1": {} }
  }
  ```

### 2) Codespaces Secrets

- Global (user/org):
  - `OPENAI_API_KEY` (Codex/AI tools)
  - `TAVILY_API_KEY` (optional; Tavily MCP)
  - `VERCEL_TOKEN` (optional; Vercel MCP)
- Per-repo:
  - `MONGODB_URI` (project DB; used by MongoDB MCP)
  - `CR_PAT` (only if pulling private GHCR images)

Create/refresh your Codespace after adding secrets so they are injected.

### 3) Dotfiles (automatic MCP + Codex setup)

Recommended for “it just works” MCP in every Codespace:
- Enable a Dotfiles repo in GitHub Settings → Codespaces → Dotfiles.
- In the dotfiles install script, write remote VS Code settings at `$HOME/.vscode-remote/data/Machine/settings.json`:
  - `mcp.servers`: MongoDB (stdio using `${env:MONGODB_URI}`), Vercel (http with `Authorization: Bearer ${env:VERCEL_TOKEN}`), Context7 (http), GitHub MCP (http; requires Copilot login in Codespaces).
  - `claude.mcpServers` (if you use Claude Code): context7 only (no token).
- Also write Codex config at `~/.codex/config.toml` for context7 and optional Tavily.

#### Notes on VS Code MCP
- In web Codespaces, VS Code MCP has limitations (CORS/stdio). Prefer Codex/Claude CLI MCP in Codespaces, or use VS Code Desktop to connect to the Codespace if you need MCP tools inside VS Code.

#### Speed-ups
- Base image preinstalls MCP helpers: `mcp-remote`, `mongodb-mcp-server`.
- Dotfiles can also warm up the npx cache to reduce first-run latency.

### 4) First-time steps inside the container

```bash
vercel login
vercel env pull .env.local
npm run dev
```

### 5) Troubleshooting tips

- Server Actions in Codespaces: allow `*.app.github.dev` in `next.config.ts` under `experimental.serverActions.allowedOrigins` and optionally `localhost:3000` in dev; set NextAuth `trustHost: true`.
- Codex OAuth in web Codespaces: prefer `OPENAI_API_KEY` env, or use VS Code Desktop with port 1455 forwarding.
- Vercel `env pull` overwrites `.env.local`: avoid auto-writing to `.env.local` from scripts.

## 🏷️ Versioning

This image follows [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes to the base environment
- **MINOR**: New features, CLI tool updates
- **PATCH**: Bug fixes, security updates

## 🤝 Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.
