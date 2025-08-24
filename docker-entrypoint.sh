#!/bin/bash
# =============================================================================
# TRUPIN NODE.JS DEVELOPMENT BASE - CONTAINER ENTRYPOINT
# =============================================================================
# Handles runtime setup for Node.js development containers:
# - CLI tools installation (Vercel, Claude Code, OpenAI Codex)
# - Volume permission management
# - Shell environment setup

set -euo pipefail

# Ensure PATH includes system directories and Node.js binaries
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/lib/node_modules/.bin:/home/node/.npm-global/bin:$PATH"

echo "🐳 Trupin Node.js development container starting..."

# Ensure important directories exist
ensure_dirs() {
  for d in \
    /home/node/.npm-global \
    /home/node/.vercel \
    /home/node/.codex \
    /home/node/.config \
    /home/node/.cache; do
    /usr/bin/mkdir -p "$d"
  done
}

ensure_dirs

# If running as root, fix permissions on mounted volumes, then re-exec as node
if [ "$(id -u)" = "0" ]; then
  echo "🔧 Ensuring volume permissions for node user..."
  chown -R node:node /home/node/.npm-global /home/node/.vercel /home/node/.codex /home/node/.config /home/node/.cache || true
  # Re-run this script as node to avoid root-owned files on installs
  exec gosu node /usr/local/bin/docker-entrypoint.sh "$@"
fi

# Ensure PATH is available in interactive shells (zsh/bash)
for rc in "/home/node/.zshrc" "/home/node/.bashrc" "/home/node/.profile" "/home/node/.bash_profile"; do
  if [ -f "$rc" ]; then
    if ! grep -q "/home/node/.npm-global/bin" "$rc"; then
      echo 'export PATH="/home/node/.npm-global/bin:$PATH"' >> "$rc"
    fi
  else
    echo 'export PATH="/home/node/.npm-global/bin:$PATH"' > "$rc"
  fi
done

# === CLI TOOLS INSTALLATION ===
# Install development CLI tools at runtime (non-critical)
# Persist a marker in npm-global to avoid reinstalling on every startup
if [ -z "${SKIP_CLI_INSTALL:-}" ]; then
  if [ ! -f /home/node/.npm-global/.cli-tools-installed ] || ! command -v vercel >/dev/null 2>&1 || ! command -v codex >/dev/null 2>&1; then
    echo "🛠️ Installing CLI tools (first run or missing)..."
    
    # Allow version overrides via environment variables
    VERCEL_CLI_VERSION=${VERCEL_CLI_VERSION:-latest}
    CLAUDE_CODE_VERSION=${CLAUDE_CODE_VERSION:-latest}
    CODEX_CLI_VERSION=${CODEX_CLI_VERSION:-latest}
    
    if npm install -g \
      "vercel@${VERCEL_CLI_VERSION}" \
      "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
      "@openai/codex@${CODEX_CLI_VERSION}" 2>/dev/null; then
      touch /home/node/.npm-global/.cli-tools-installed
      echo "✅ CLI tools installed"
    else
      echo "⚠️ CLI tools installation failed (non-critical)"
    fi
  else
    echo "✅ CLI tools already available"
  fi
fi

# === RUNTIME CONFIGURATION ===
# Copy project-specific configs if available
if [ -f /app/.devcontainer/codex/config.toml ] && [ ! -f /home/node/.codex/config.toml ]; then
  echo "⚙️ Setting up Codex configuration..."
  /usr/bin/mkdir -p /home/node/.codex
  cp /app/.devcontainer/codex/config.toml /home/node/.codex/config.toml
  echo "✅ Codex config ready"
fi

echo "✅ Container ready!"

# Execute provided command or fall back to a long-lived process
if [ "$#" -gt 0 ]; then
  exec "$@"
else
  echo "ℹ️ No command provided; sleeping to keep container alive."
  exec sleep infinity
fi