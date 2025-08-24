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
    /app \
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
  # Optionally enable passwordless sudo for node (default: enabled). Set ENABLE_PASSWORDLESS_SUDO=0 to disable.
  if [ "${ENABLE_PASSWORDLESS_SUDO:-1}" = "1" ]; then
    echo 'node ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/node
    chmod 0440 /etc/sudoers.d/node
  else
    rm -f /etc/sudoers.d/node || true
  fi

  echo "🔧 Ensuring volume permissions for node user..."
  chown -R node:node /app /home/node/.npm-global /home/node/.vercel /home/node/.codex /home/node/.config /home/node/.cache || true
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

# CLI tools are preinstalled at image build time; no runtime install

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
  echo "🚀 Executing command: $*"
  exec "$@"
else
  echo "ℹ️ No command provided; sleeping to keep container alive."
  exec sleep infinity
fi
