#!/usr/bin/env bash
set -euo pipefail

# OpenClaw Workspace Setup
# Idempotent — safe to run multiple times

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
DEFAULT_WORKSPACE="$HOME/clawd"
WORKSPACE="$DEFAULT_WORKSPACE"
NON_INTERACTIVE=0
SKIP_COMMIT=0
SKIP_GIT_INIT=0
GIT_NAME="${GIT_AUTHOR_NAME:-${GIT_COMMITTER_NAME:-}}"
GIT_EMAIL="${GIT_AUTHOR_EMAIL:-${GIT_COMMITTER_EMAIL:-}}"

usage() {
  cat <<'EOF'
Usage: ./setup.sh [options]

Options:
  --workspace PATH       Workspace path (default: ~/clawd)
  --non-interactive      Do not prompt; fail if required values are missing
  --skip-commit          Initialize git but skip the initial commit
  --skip-git-init        Do not initialize a git repository
  --git-name NAME        Git author name to configure locally for a new repo
  --git-email EMAIL      Git author email to configure locally for a new repo
  -h, --help             Show this help text

Notes:
  - Interactive mode still prompts for the workspace path.
  - Git identity is only configured for a newly created repo when both name and
    email are supplied via flags or existing GIT_AUTHOR_*/GIT_COMMITTER_* env.
  - If a new repo is created without identity, the script skips the initial
    commit and explains how to finish it manually.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace)
      [[ $# -ge 2 ]] || { echo "error: --workspace requires a value" >&2; exit 1; }
      WORKSPACE="$2"
      shift 2
      ;;
    --non-interactive)
      NON_INTERACTIVE=1
      shift
      ;;
    --skip-commit)
      SKIP_COMMIT=1
      shift
      ;;
    --skip-git-init)
      SKIP_GIT_INIT=1
      shift
      ;;
    --git-name)
      [[ $# -ge 2 ]] || { echo "error: --git-name requires a value" >&2; exit 1; }
      GIT_NAME="$2"
      shift 2
      ;;
    --git-email)
      [[ $# -ge 2 ]] || { echo "error: --git-email requires a value" >&2; exit 1; }
      GIT_EMAIL="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

WORKSPACE="${WORKSPACE/#\~/$HOME}"

if [[ $NON_INTERACTIVE -eq 0 && "$WORKSPACE" == "$DEFAULT_WORKSPACE" ]]; then
  echo "🦞 OpenClaw Workspace Setup"
  echo "==========================="
  echo ""
  read -rp "Workspace path [~/clawd]: " WORKSPACE_INPUT
  WORKSPACE_INPUT="${WORKSPACE_INPUT:-$WORKSPACE}"
  WORKSPACE="${WORKSPACE_INPUT/#\~/$HOME}"
else
  echo "🦞 OpenClaw Workspace Setup"
  echo "==========================="
  echo ""
fi

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
  "openclaw.example.json"
)

for tmpl in "${templates[@]}"; do
  target="$WORKSPACE/$tmpl"
  if [ "$tmpl" = "openclaw.example.json" ]; then
    target="$WORKSPACE/config/$tmpl"
  fi

  if [ ! -f "$target" ]; then
    if [ -f "$TEMPLATES_DIR/$tmpl" ]; then
      cp "$TEMPLATES_DIR/$tmpl" "$target"
      echo "  📄 Copied ${tmpl} → ${target#$WORKSPACE/}"
    else
      echo "  ⚠️  Template $tmpl not found in $TEMPLATES_DIR"
    fi
  else
    echo "  ⏭️  ${target#$WORKSPACE/} already exists (not overwriting)"
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
if [ "$SKIP_GIT_INIT" -eq 1 ]; then
  echo "  ⏭️  Skipping git initialization (--skip-git-init)"
elif [ ! -d "$WORKSPACE/.git" ]; then
  (
    cd "$WORKSPACE"
    git init -q

    if [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]]; then
      git config user.name "$GIT_NAME"
      git config user.email "$GIT_EMAIL"
      echo "  🔧 Configured local git identity for new repo"
    fi

    git add -A

    if [ "$SKIP_COMMIT" -eq 1 ]; then
      echo "  ⏭️  Initialized git repository (initial commit skipped)"
    elif git config user.name >/dev/null && git config user.email >/dev/null; then
      git commit -q -m "Initial workspace setup via openclaw-playbook"
      echo "  🔧 Initialized git repository"
    else
      echo "  ⚠️  Initialized git repository, but skipped initial commit because git user.name/user.email are not configured"
      echo "     Re-run with --git-name/--git-email, set git config, or commit manually later"
    fi
  )
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
echo "  6. Read the playbook: playbook/01-foundations.md through 16-infrastructure.md"
echo "  7. Build your scripts in $WORKSPACE/scripts/"
echo "  8. Build your hooks in $WORKSPACE/hooks/"
echo ""
echo "📖 Start with: playbook/01-foundations.md"
echo ""
echo "Remember: this setup does NOT touch openclaw.json or any running config."
echo "Use $WORKSPACE/config/openclaw.example.json as your starting point for config."
echo "Configure OpenClaw separately to point at this workspace."
