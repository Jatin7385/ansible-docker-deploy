#!/usr/bin/env bash
# Installs Ansible + required collections on Ubuntu/Debian (or other common
# Linux distros as a fallback) so this project can run against localhost.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

VENV_DIR="$PROJECT_DIR/.venv"

if command -v apt >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y python3-venv python3-pip
fi

python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

python -m pip install --upgrade pip
python -m pip install --upgrade ansible
python -m pip install --upgrade docker

echo "Installing required Ansible collections..."
ansible-galaxy collection install -r "$PROJECT_DIR/requirements.yml"

echo
echo "Setup complete."
echo "Run:"
echo "  source .venv/bin/activate"
echo

echo "Done. Verify with: ansible --version"
