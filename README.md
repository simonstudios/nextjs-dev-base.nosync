# Next.js Development Base Image

A production-ready Next.js development base image optimized for VS Code devcontainers and GitHub Codespaces.

## 🚀 Features

- **Node.js 22** (bookworm-slim base)
- **Pre-installed CLI tools**:
  - Vercel CLI
  - Claude Code
  - OpenAI Codex
- **Volume permission management** for seamless file sharing
- **Optimized for devcontainers** and Codespaces
- **Multi-architecture support** (AMD64, ARM64)

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

# Default command (inherited from base: npm run dev)
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

### Environment Variables

- `SKIP_CLI_INSTALL=true` - Skip CLI tools installation
- `VERCEL_CLI_VERSION=latest` - Specify Vercel CLI version
- `CLAUDE_CODE_VERSION=latest` - Specify Claude Code version  
- `CODEX_CLI_VERSION=latest` - Specify Codex CLI version

### Volume Mounts

The image expects these volumes for persistence:

- `/home/node/.npm-global` - CLI tools cache
- `/home/node/.vercel` - Vercel authentication
- `/home/node/.codex` - Codex configuration
- `/home/node/.config` - General CLI configs
- `/home/node/.cache` - CLI caches

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