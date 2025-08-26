# =============================================================================
# NEXT.JS DEVELOPMENT BASE IMAGE
# =============================================================================
# Provides a complete Node.js development environment with:
# - CLI tools (Vercel, Claude Code, OpenAI Codex)
# - Volume permission management
# - Development utilities
# - Optimized for devcontainers and Codespaces

FROM node:22-bookworm-slim AS development

LABEL org.opencontainers.image.title="Next.js Dev Base"
LABEL org.opencontainers.image.description="Next.js development base image with CLI tools"
LABEL org.opencontainers.image.vendor="Next.js Dev Base"

# Disable interactive prompts during build
ARG DEBIAN_FRONTEND=noninteractive

# Build-time configuration for CLI installation and version pinning
ARG SKIP_CLI_INSTALL=false
ARG VERCEL_CLI_VERSION=latest
ARG CLAUDE_CODE_VERSION=latest
ARG CODEX_CLI_VERSION=latest
# Optional MCP helper versions
ARG MCP_REMOTE_VERSION=latest
ARG MONGODB_MCP_SERVER_VERSION=latest

# === SYSTEM DEPENDENCIES ===
# Install essential system packages in single layer for optimal caching
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl git ca-certificates gosu coreutils sudo zsh \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# === SETUP DIRECTORIES AND PERMISSIONS ===
# Create necessary directories and set permissions in one layer
RUN mkdir -p /home/node/.npm-global /app \
    && chown -R node:node /home/node /app

WORKDIR /app

# Switch to node user for all npm operations (security best practice)
USER node

# Configure npm global directory (build-time setup)
RUN npm config set prefix /home/node/.npm-global \
    && echo 'export PATH=/home/node/.npm-global/bin:$PATH' >> /home/node/.bashrc

# Ensure global npm bin is on PATH for all shells/processes
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global \
    PATH=/home/node/.npm-global/bin:$PATH

# Pre-install core CLI tools so they are always available
RUN if [ "${SKIP_CLI_INSTALL}" != "true" ]; then \
      npm install -g \
        "vercel@${VERCEL_CLI_VERSION}" \
        "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
        "@openai/codex@${CODEX_CLI_VERSION}" \
        "mcp-remote@${MCP_REMOTE_VERSION}" \
        "mongodb-mcp-server@${MONGODB_MCP_SERVER_VERSION}"; \
    else \
      echo "Skipping CLI tool installation"; \
    fi \
    && touch /home/node/.npm-global/.cli-tools-installed

# === PORT EXPOSURE ===
# Common development ports
EXPOSE 3000 1455

# Copy entrypoint script as node user
COPY --chown=node:node docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Switch back to root to make entrypoint executable and set final runtime user
USER root
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Seed script to ensure user-scope MCP config for Codex/Claude is present in every Codespace
COPY --chown=root:root seed-mcp /usr/local/bin/seed-mcp
RUN chmod +x /usr/local/bin/seed-mcp

# === CONTAINER STARTUP ===
# Run as root initially so entrypoint can handle permissions properly
USER root
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["sleep", "infinity"]
