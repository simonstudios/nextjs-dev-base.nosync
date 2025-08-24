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

# === SYSTEM DEPENDENCIES ===
# Install essential system packages in single layer for optimal caching
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl git ca-certificates gosu coreutils \
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

# === PORT EXPOSURE ===
# Common development ports
EXPOSE 3000 1455

# Copy entrypoint script as node user
COPY --chown=node:node docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Switch back to root only to make entrypoint executable
USER root
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# === CONTAINER STARTUP ===
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["npm", "run", "dev"]