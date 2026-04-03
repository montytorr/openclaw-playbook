#!/usr/bin/env bash
set -euo pipefail

# OpenClaw Workspace Setup
# Idempotent — safe to run multiple times

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

echo "🦞 OpenClaw Workspace Setup"
echo "==========================="
echo ""

# Ask for workspace path
read -rp "Workspace path [~/clawd]: " WORKSPACE
WORKSPACE="${WORKSPACE:-$HOME/clawd}"
WORKSPACE="${WORKSPACE/#\~/$HOME}"

echo ""
echo "Setting up workspace at: $WORKSPACE"
echo ""

# Create directory structure
dirs=(
  "memory"
  "projects"
  "projects/archive"
  "scripts"
  "hooks"
  "config"
  "logs"
  "canvas"
  "security"
  "data"
  "feedback"
  ".proposed"
)

for dir in "${dirs[@]}"; do
  if [ ! -d "$WORKSPACE/$dir" ]; then
    mkdir -p "$WORKSPACE/$dir"
    echo "  ✅ Created $dir/"
  else
    echo "  ⏭️  $dir/ already exists"
  fi
done

echo ""

# Copy templates (only if target doesn't exist)
templates=(
  "AGENTS.md"
  "SOUL.md"
  "IDENTITY.md"
  "USER.md"
  "HEARTBEAT.md"
  "TOOLS.md"
  "SECURITY.md"
)

for tmpl in "${templates[@]}"; do
  if [ ! -f "$WORKSPACE/$tmpl" ]; then
    if [ -f "$TEMPLATES_DIR/$tmpl" ]; then
      cp "$TEMPLATES_DIR/$tmpl" "$WORKSPACE/$tmpl"
      echo "  📄 Copied $tmpl"
    else
      echo "  ⚠️  Template $tmpl not found in $TEMPLATES_DIR"
    fi
  else
    echo "  ⏭️  $tmpl already exists (not overwriting)"
  fi
done

echo ""

# Create .gitignore
GITIGNORE="$WORKSPACE/.gitignore"
if [ ! -f "$GITIGNORE" ]; then
  cat > "$GITIGNORE" << 'EOF'
# Environment & secrets
.env
.env.*
*.key
*.pem

# Auto-generated memory index
MEMORY.md

# Databases
*.db
*.db-journal
*.db-wal
*.db-shm

# Logs
logs/

# Proposed edits (staging area)
.proposed/

# Data directory (runtime state)
data/

# OS files
.DS_Store
Thumbs.db

# Node modules (if any scripts use them)
node_modules/

# Python virtual environments
.venv/
__pycache__/
EOF
  echo "  📄 Created .gitignore"
else
  echo "  ⏭️  .gitignore already exists"
fi

echo ""

# Initialize git repo
if [ ! -d "$WORKSPACE/.git" ]; then
  cd "$WORKSPACE"
  git init -q
  git add -A
  git commit -q -m "Initial workspace setup via openclaw-playbook"
  echo "  🔧 Initialized git repository"
else
  echo "  ⏭️  Git repository already initialized"
fi

echo ""
echo "✅ Workspace setup complete!"
echo ""
echo "Next steps:"
echo "  1. Edit $WORKSPACE/IDENTITY.md — give your agent a name and personality"
echo "  2. Edit $WORKSPACE/SOUL.md — define voice, boundaries, and behavioral guardrails"
echo "  3. Edit $WORKSPACE/USER.md — tell your agent about yourself"
echo "  4. Edit $WORKSPACE/AGENTS.md — customize the instruction set"
echo "  5. Edit $WORKSPACE/SECURITY.md — set your security rules"
echo "  6. Read the playbook: playbook/01-foundations.md through 15-context-management.md"
echo "  7. Build your scripts in $WORKSPACE/scripts/"
echo "  8. Build your hooks in $WORKSPACE/hooks/"
echo ""
echo "📖 Start with: playbook/01-foundations.md"
echo ""
echo "Remember: this setup does NOT touch openclaw.json or any running config."
echo "Configure OpenClaw separately to point at this workspace."
