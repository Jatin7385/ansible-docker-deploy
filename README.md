# ansible-docker-deploy

Reusable Ansible playbook that sets up Docker (if not already installed and
running) and then pulls + runs any Docker image you point it at — across
**macOS, Ubuntu, and Windows**. One playbook, one set of `-e` flags per run;
it auto-detects the target OS and runs the right setup steps.

```
ansible-docker-deploy/
├── ansible.cfg
├── inventory.ini
├── playbook.yml          # entry point — detects OS, dispatches, deploys
├── requirements.yml
├── tasks/
│   ├── macos.yml         # Homebrew Cask -> Docker Desktop
│   ├── ubuntu.yml        # apt -> Docker Engine + systemd
│   └── windows.yml       # Chocolatey -> Docker Desktop
├── scripts/
│   ├── setup-mac.sh      # installs Ansible via Homebrew
│   ├── setup-linux.sh    # installs Ansible via apt/dnf/yum
│   └── setup-windows.ps1 # bootstraps WSL, installs Ansible inside it
└── README.md
```

## Important: how each OS is actually reached

| Target  | Connection                  | Notes |
|---------|------------------------------|-------|
| macOS   | Local (`ansible_connection=local`) | No SSH. Run Ansible directly on the Mac. |
| Ubuntu  | Local, **or** SSH to a separate box | If this control machine *is* Ubuntu, run local. Otherwise SSH like any normal Linux target. |
| Windows | **WinRM**, always            | Ansible has no native Windows control node (short of running inside WSL). To manage a Windows machine — even one on your own desk — you must run `ansible-playbook` from a Mac/Linux/WSL machine and connect to Windows over WinRM. There is no "local, no network" option for Windows targets. |

Windows targets need WinRM listener enabled on the Windows side first:
```powershell
# Run once on the Windows machine, in an elevated PowerShell:
winrm quickconfig
Enable-PSRemoting -Force
```

## One-time setup (on the control machine)

Run the setup script matching the machine you're running Ansible *from*
(not necessarily the machine you're deploying *to*):

| Control machine | Script |
|------------------|--------|
| macOS            | `scripts/setup-mac.sh` |
| Ubuntu/Linux     | `scripts/setup-linux.sh` |
| Windows          | `scripts/setup-windows.ps1` (run as Administrator) |

```bash
# macOS
./scripts/setup-mac.sh

# Ubuntu/Linux
./scripts/setup-linux.sh
```

```powershell
# Windows (elevated PowerShell)
.\scripts\setup-windows.ps1
```

Each script installs Ansible and the collections in `requirements.yml`. The
Windows script is a special case: since Ansible has no native Windows
control node, it bootstraps WSL + Ubuntu (prompting for a reboot if WSL
isn't already installed) and installs Ansible *inside* WSL — that's the
actual environment you'll run `ansible-playbook` from, even on a Windows
machine. It also installs `pywinrm`, needed if that WSL environment will
itself manage other Windows targets over WinRM.

Edit `inventory.ini` to uncomment/fill in the host(s) you're targeting.

## Usage

Same playbook, same flags, regardless of target OS:

```bash
ansible-playbook playbook.yml \
  -l <macos|ubuntu|windows> \
  -e docker_image=<image:tag> \
  -e container_name=<name> \
  -e '{"docker_ports": ["<host_port>:<container_port>"]}'
```

`-l` limits the run to one inventory group (recommended, since only one
group is likely to be filled in/reachable at a time).

### Examples

macOS, local:
```bash
ansible-playbook playbook.yml -l macos \
  -e docker_image=nginx:latest \
  -e container_name=my-nginx \
  -e '{"docker_ports": ["8080:80"]}'
```

Ubuntu, local:
```bash
ansible-playbook playbook.yml -l ubuntu \
  -e docker_image=nginx:latest \
  -e container_name=my-nginx \
  -e '{"docker_ports": ["8080:80"]}'
```

Windows, over WinRM:
```bash
ansible-playbook playbook.yml -l windows \
  -e docker_image=nginx:latest \
  -e container_name=my-nginx \
  -e '{"docker_ports": ["8080:80"]}'
```

Nginx, minimal (no volume needed — just serves the default welcome page):
```bash
ansible-playbook playbook.yml -l macos \
  -e docker_image=nginx:latest \
  -e container_name=nginx \
  -e '{"docker_ports": ["8080:80"]}'
```
Verify with `curl http://localhost:8080`.

Jenkins (two ports — web UI + agent connections — and a named volume so
jobs/config persist across container restarts):
```bash
ansible-playbook playbook.yml -l macos \
  -e docker_image=jenkins/jenkins:lts \
  -e container_name=jenkins \
  -e '{"docker_ports": ["8080:8080", "50000:50000"], "docker_volumes": ["jenkins_home:/var/jenkins_home"]}'
```
Verify at `http://localhost:8080` once it finishes starting up.

Image needing env vars and a mounted volume (works the same on any OS):
```bash
ansible-playbook playbook.yml -l macos \
  -e docker_image=myrepo/myapp:latest \
  -e container_name=myapp \
  -e '{
        "docker_ports": ["3000:3000"],
        "docker_env": {"NODE_ENV": "production"},
        "docker_volumes": ["/Users/you/data:/app/data"]
      }'
```

## Variables

| Variable         | Required | Default | Description                                  |
|------------------|----------|---------|-----------------------------------------------|
| `docker_image`   | yes      | —       | Image to pull and run, e.g. `nginx:latest`    |
| `container_name` | no       | `app`   | Name given to the running container           |
| `docker_ports`   | no       | `[]`    | List of `"host:container"` port mappings      |
| `docker_env`     | no       | `{}`    | Dict of environment variables for the container |
| `docker_volumes` | no       | `[]`    | List of `"host_path:container_path"` mounts   |

## Notes

- **macOS**: first run installs Docker Desktop via Homebrew Cask if missing,
  then launches it. Docker Desktop needs its license dialog clicked through
  once on first launch — a one-time manual step Ansible can't avoid.
- **Ubuntu**: installs Docker Engine (not Desktop) via apt, enables it as a
  systemd service, and adds the connecting user to the `docker` group (takes
  effect on next login/shell).
- **Windows**: installs Docker Desktop via Chocolatey, plus Python (required
  for the `docker_image`/`docker_container` Ansible modules to talk to the
  Docker Engine API on the target). Docker Desktop's first-launch license
  dialog applies here too.
- Re-running the playbook is idempotent on all three platforms: already-
  installed/running Docker is detected and skipped, and `docker_container`
  reconciles the container to the desired state.
- To stop/remove a deployed container, use `docker stop <container_name>` /
  `docker rm <container_name>` directly, or extend the playbook with a
  `state: absent` variant.
