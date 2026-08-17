# Sets up Ansible for this project on Windows.
#
# IMPORTANT: Ansible cannot run as a control node natively on Windows.
# This script bootstraps WSL + Ubuntu (if not already present) and installs
# Ansible *inside* WSL, since that's the actual control environment you'll
# run ansible-playbook from. It also installs pywinrm inside WSL so that
# environment can, if needed, manage OTHER Windows machines over WinRM.
#
# Run this in an elevated (Administrator) PowerShell prompt.

$ErrorActionPreference = "Stop"

$wslCheck = wsl --list --verbose 2>$null
if (-not $?) {
    Write-Host "WSL not detected. Installing WSL with Ubuntu..."
    wsl --install -d Ubuntu
    Write-Host ""
    Write-Host "A reboot is required to finish installing WSL."
    Write-Host "After rebooting, re-run this script to finish installing Ansible."
    exit 0
}

Write-Host "Installing Ansible inside WSL (Ubuntu)..."
wsl -d Ubuntu -- bash -c "sudo apt update && sudo apt install -y ansible python3-pip && pip3 install --user pywinrm"

$projectPathWindows = Split-Path -Parent $PSScriptRoot
$projectPathWsl = wsl -d Ubuntu -- wslpath -a "$projectPathWindows"

Write-Host "Installing required Ansible collections..."
wsl -d Ubuntu -- bash -c "ansible-galaxy collection install -r '$projectPathWsl/requirements.yml'"

Write-Host ""
Write-Host "Done. To run playbooks, open a WSL shell (wsl -d Ubuntu) and cd into:"
Write-Host "  $projectPathWsl"
