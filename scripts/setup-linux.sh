#!/usr/bin/env bash
# Installs Ansible + required collections on Ubuntu/Debian (or other common
# Linux distros as a fallback) so this project can run against localhost.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if command -v ansible &> /dev/null; then
  echo "Ansible already installed: $(ansible --version | head -n1)"
elif command -v apt &> /dev/null; then
  echo "Installing Ansible via apt..."
  sudo apt update
  sudo apt install -y ansible python3-pip
elif command -v dnf &> /dev/null; then
  echo "Installing Ansible via dnf..."
  sudo dnf install -y ansible
elif command -v yum &> /dev/null; then
  echo "Installing Ansible via yum..."
  sudo yum install -y ansible
else
  echo "No supported package manager found (apt/dnf/yum)." >&2
  echo "Install Ansible manually: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html" >&2
  exit 1
fi

echo "Installing required Ansible collections..."
ansible-galaxy collection install -r "$PROJECT_DIR/requirements.yml"

echo "Done. Verify with: ansible --version"
