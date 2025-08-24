#!/bin/bash
# =============================================================================
# NODE.JS DEVELOPMENT BASE - CONTAINER ENTRYPOINT
# =============================================================================
# Handles runtime setup for Node.js development containers:
# - Volume permission management
# - Shell environment setup
# - Optional passwordless sudo configuration

set -euo pipefail

# Ensure PATH includes system directories and Node.js binaries
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/lib/node_modules/.bin:/home/node/.npm-global/bin:$PATH"

echo "🐳 Node.js development container starting..."

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
  # Configure sudo access based on environment variable (default: disabled for security)
  if [ "${ENABLE_PASSWORDLESS_SUDO:-0}" = "1" ]; then
    echo "⚠️  Enabling passwordless sudo (development only)..."
    echo 'node ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/node
    chmod 0440 /etc/sudoers.d/node
  else
    # Remove any existing sudo config for node user
    rm -f /etc/sudoers.d/node 2>/dev/null || true
  fi

  echo "🔧 Ensuring volume permissions for node user..."
  # Only chown if directories exist and aren't already owned by node
  for dir in /app /home/node/.npm-global /home/node/.vercel /home/node/.codex /home/node/.config /home/node/.cache; do
    if [ -d "$dir" ] && [ "$(stat -c %u "$dir")" != "1000" ]; then
      chown -R node:node "$dir"
    fi
  done
  
  # Re-run this script as node to avoid root-owned files
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

# CLI tools are preinstalled at image build time

# === RUNTIME CONFIGURATION ===
# Copy project-specific configs if available (only if source exists)
if [ -f /app/.devcontainer/codex/config.toml ] && [ ! -f /home/node/.codex/config.toml ]; then
  echo "⚙️  Setting up Codex configuration..."
  mkdir -p /home/node/.codex
  cp /app/.devcontainer/codex/config.toml /home/node/.codex/config.toml
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
