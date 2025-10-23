# Claude YOLO - Safe Devcontainer for Claude Code

**YOLO** = **Y**ou **O**nly **L**ive in a c**O**ntainer

_(Claude came up with that high-larious pun all on its own btw when I told it to write this README)_

This repository provides a VS Code [_devcontainer_](https://code.visualstudio.com/docs/devcontainers/containers) setup
that allows Claude Code to run with full permissions (`--dangerously-skip-permissions`) in a sandboxed Docker
environment. This gives Claude the freedom to make changes without constant permission prompts, while keeping your host
system safe through container isolation. Inspired by Claude's documentation on [Development
Containers](https://docs.claude.com/en/docs/claude-code/devcontainer) and Claude's development container configuration
in their [Claude Code github repo](https://github.com/anthropics/claude-code).

This is purely for educational purposes, demonstrating how you could use Claude's devcontainer setup for your own
projects. I offer no guarantees on the security aspects of this approach, or even that it's working at all.

---
> **⚠️ DISCLAIMER**: Docker isolation provides no absolute guarantees, and letting it use your host's Chrome obviously
> breaks isolation, and it can still _potentially_ destroy whatever is inside your project and your `~/.claude`. So
> while it's _safer_ than bypassing permissions on your host, and much less annoying than either maintaining
> `permissions` blocks in your `settings.json` or selecting `yes and don't ask again for similar commands`, you trade
> some level of security for some level of convenience, as is often the case. 💀
>
> ALSO: Antrophic's [repo](https://github.com/anthropics/claude-code/tree/main/.devcontainer) has an
> [`init-firewall.sh`](https://github.com/anthropics/claude-code/blob/main/.devcontainer/init-firewall.sh) script
> that I am not using, so please be aware of this.
---

## Table of Contents

- [Key Features](#key-features)
- [Why does this exist?](#why-does-this-exist)
- [Prerequisites](#prerequisites)
  - [Required](#required)
  - [Optional (for Chrome DevTools integration)](#optional-for-chrome-devtools-integration)
- [System Requirements](#system-requirements)
- [Installation](#installation)
  - [Installation Options](#installation-options)
  - [Examples](#examples)
  - [What Gets Installed](#what-gets-installed)
  - [Manual Installation (Alternative)](#manual-installation-alternative)
- [Installation in your own project](#installation-in-your-own-project)
- [Usage](#usage)
  - [Method 1: Inside VS Code](#method-1-inside-vs-code)
  - [Method 2: From Host Terminal](#method-2-from-host-terminal)
  - [With Chrome DevTools Integration](#with-chrome-devtools-integration)
- [How it works](#how-it-works)
  - [Architecture](#architecture)
  - [Security Model](#security-model)
  - [What gets mounted](#what-gets-mounted)
- [Configuration](#configuration)
  - [Customizing the Container](#customizing-the-container)
  - [Customizing MCP Servers](#customizing-mcp-servers)
- [Running Chrome with remote debugging enabled](#running-chrome-with-remote-debugging-enabled)
- [Troubleshooting](#troubleshooting)
  - [Container won't start](#container-wont-start)
  - [Chrome DevTools connection fails](#chrome-devtools-connection-fails)
  - [Claude authentication issues](#claude-authentication-issues)
  - [Permission denied errors](#permission-denied-errors)
- [Advanced Usage](#advanced-usage)
  - [Running without VS Code](#running-without-vs-code)
  - [Accessing the container shell](#accessing-the-container-shell)
  - [Adding packages to the container](#adding-packages-to-the-container)
- [License](#license)
- [Acknowledgments](#acknowledgments)

### Key Features

- **Isolation**: Claude runs with full permissions inside a Docker container, protecting your host system
- **Access to your workspace**: Your project directory is mounted in the container under `/workspace`.
- **Access to `~/.claude`**: Uses your existing claude config, plugins, etcetera
- **Chrome DevTools integration**: Drive Chrome running on your host from Claude MCP inside the container
- **Persistent configuration**: Your Claude authentication persists across container restarts
- **Zero permission prompts**: Claude can freely modify files and run commands within the container
- **Easy to use**: Single script to run Claude from anywhere (inside container or on the host)

## Why does this exist?

Claude Code's `--dangerously-skip-permissions` flag allows Claude to operate without constant permission prompts, but
using it directly on your host system ~~can be risky~~ _is super dangerous_. This setup provides the best of both
worlds:

1. **Freedom for Claude**: Claude can do whatever it wants inside the container, without begging you for permission
2. **Safety for you**: The "blast radius" for Claude messing up is limited to the container and mounted workspace
3. **Browser automation**: The Chrome DevTools MCP server integration allows Claude to interact with a running Chrome
   browser for testing and debugging

## Prerequisites

### Required

- **Docker Desktop** (macOS/Windows) or **Docker Engine** (Linux) - _(NOTE: only macOS is tested, by me, and only
  barely)_

  - macOS: Get [Docker Desktop](https://www.docker.com/products/docker-desktop/) or `brew install --cask docker`
  - Windows: Download from [docker.com](https://www.docker.com/products/docker-desktop)
  - Linux: Follow [official Docker installation guide](https://docs.docker.com/engine/install/)

- **Node.js and npm** (v18 or later, needed for `devcontainer cli`)

  - macOS: `brew install node`
  - Ubuntu/Debian: `sudo apt install nodejs npm`
  - Or download from [nodejs.org](https://nodejs.org/)

- **VS Code** with the following extensions:

  - [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
    (`ms-vscode-remote.remote-containers`)

- **Claude Code** authentication
  - The first time you run the container and fire up claude inside it, it will ask you to authenticate by opening an
    OAuth link and pasting the auth code. Credentials will be persisted on the Docker volume between restarts.

### Optional (for Chrome DevTools integration)

- **Google Chrome** or **Chromium** browser
  - macOS: [Download Chrome](https://www.google.com/chrome) or `brew install --cask google-chrome`
  - Ubuntu/Debian: `sudo apt install google-chrome-stable`

## System Requirements

- **Disk space**: ~3-5GB for the Docker image (first build)
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Platform**: macOS (Intel/ARM), Windows (with WSL2), _Linux probably doesn't work due to differences in the
  networking stacks_

## Installation

Install claude-yolo in your existing project with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/Qrtr-ai/claude-yolo/main/install.sh | sh
```

Or inspect the script before running:

```bash
curl -fsSL https://raw.githubusercontent.com/Qrtr-ai/claude-yolo/main/install.sh -o install.sh
sh install.sh
```

### Installation Options

- `--force` - Overwrite existing files without prompting
- `--branch NAME` - Install from a specific branch (default: main)
- `--help` - Show help message

### Examples

```bash
# Install with force overwrite
sh install.sh --force

# Install from develop branch
sh install.sh --branch develop
```

### What Gets Installed

The installer creates the following files in your project:

- `.devcontainer/devcontainer.json` - VS Code devcontainer configuration
- `.devcontainer/Dockerfile` - Container image definition
- `scripts/claude` - Wrapper script for running Claude Code
- `scripts/launch-chrome.sh` - Host-side Chrome launcher

### Manual Installation (Alternative)

If you prefer to set this up manually:

1. **Clone this repository**:

   ```sh
   git clone https://github.com/Qrtr-ai/claude-yolo.git
   cd claude-yolo
   ```

2. **Open in VS Code**:

   ```sh
   code .
   ```

3. **Reopen in container**:

   - When prompted, click "Reopen in Container"
   - Or use Command Palette (Cmd/Ctrl+Shift+P) → "Dev Containers: Reopen in Container"
   - First build takes 5-10 minutes (subsequent builds use cache)

4. **Claude Code first run** (if you haven't already):

   ```sh
   claude
   ```

   Then if asked, follow the prompts to select a theme and authenticate with Anthropic. NOTE: Claude wants to open a
   link in your browser, which may or may not succeed, and the OAuth process wants to come back to claude, but since
   it's running in a container in VS Code that might not succeed. If it doesn't work automatically, copy the URL claude
   displays, plonk it in a browser, authenticate, copy the code, then paste the code into claude. You should only have
   to do this once.

## Installation in your own project

Copy the following files to your own project, then follow steps 2-4 above:

* `.devcontainer/devcontainer.js`
* `.devcontainer/Dockerfile`
* `.scripts/claude`

Optionally, for the Chrome DevTools, also copy:

* `./scripts/launch-chrome.sh`

And add the Chrome DevTools to your MCP servers in `.mcp.json`:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": [
        "-y",
        "chrome-devtools-mcp@latest",
        "--browserUrl=http://localhost:9222",
        "--logFile=/tmp/chrome-devtools-mcp.log"
      ],
      "env": {}
    }
  }
}
```

## Usage

### Method 1: Inside VS Code

Once the container is running:

1. Open VS Code terminal (inside the container)
2. Run Claude Code with full permissions:
   ```sh
   ./scripts/claude
   ```

   Or manually:

   ```sh
   claude --dangerously-skip-permissions
   ```

Or simply open the Claude icon that runs the command "Claude Code: Open in Terminal". It will automatically open
claude code with `--dangerously-skip-permissions`.

### Method 2: From Host Terminal

You can run Claude inside the container from your host terminal:

```sh
./scripts/claude
```

This script automatically:

- Detects if you're inside or outside the container
- Starts the devcontainer if not running
- Runs Claude with `--dangerously-skip-permissions` inside the container

**NOTE**: This script can run from anywhere. I copied it to `~/opt/bin/claude` which is on my `PATH` so I can run it
from anywhere and it will automatically run in a devcontainer if you have one in your project.

### With Chrome DevTools Integration

To enable Claude to control and debug Chrome:

1. **On your host**, launch Chrome with debugging enabled:

   ```sh
   ./scripts/launch-chrome.sh
   ```

2. **Inside the container**, Claude can now use the chrome-devtools MCP server to:
   - Navigate to URLs
   - Extract page content
   - Take screenshots
   - Execute JavaScript
   - Interact with DOM elements

The container automatically proxies port 9222 from the host, so the chrome-devtools MCP server (configured in
`.mcp.json`) can connect to your host Chrome.

## How it works

### Architecture

```
┌─────────────────────────────────────────┐
│  Host System                            │
│  ┌───────────────────────────────────┐  │
│  │  Chrome (port 9222)               │  │
│  └───────────────────────────────────┘  │
│                 ▲                       │
│                 │                       │
│  ┌──────────────┘                       │
│  │        Docker Container              │
│  │  ┌────────────────────────────┐      │
│  └──│  socat proxy :9222         │<──┐  │
│     └────────────────────────────┘   │  │
│     ┌────────────────────────────┐   │  │
│     │  Claude Code               │———┘  │
│     │  + MCP chrome-devtools     │      │
│     └────────────────────────────┘      │
│     ┌────────────────────────────┐      │
│     │  /workspace (mounted)      │      │
│     └────────────────────────────┘      │
│                                         │
└─────────────────────────────────────────┘
```

### Security Model

- **Container isolation**: Claude runs as the `node` user inside a Docker container
- **Limited blast radius**: Even with `--dangerously-skip-permissions`, Claude can only affect:
  - Files in the mounted workspace (`/workspace`)
  - The container's filesystem (ephemeral, except for volumes)
- **Host protection**: Your host system remains protected by Docker's isolation
- **Persistent data**: Only specified volumes persist (bash history, Claude config)
- **Chrome with dedicated profile**: With remote debugging enabled, do not use your default Chrome profile.

### What gets mounted

- **Workspace**: Your project directory → `/workspace` (read/write)
- **Claude config**: Host `~/.claude` → `/home/node/.claude` (read/write bind mount)
  - ⚠️ **NOTE**: this directory is mounted writeable, so claude can potentially mess it up.
  - **Alternatively** you can mount a docker volume for `~/.claude` in the container to provide
    full isolation from the host's `~/.claude`. See the `.devcontainer/devcontainer.json` file for details.
- **Bash history**: Docker volume → `/commandhistory` (persistent)

---

## Configuration

### Customizing the Container

Edit `.devcontainer/devcontainer.json` to:

- Add VS Code extensions
- Configure VS Code settings
- Add environment variables
- Change container resources

Edit `.devcontainer/Dockerfile` to:

- Install additional tools (e.g., Python, Rust, etc.)
- Configure shell environment
- Add system packages

### Customizing MCP Servers

Edit `.mcp.json` to add or configure MCP servers. For example:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest", "--browserUrl=http://localhost:9222"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    }
  }
}
```

## Running Chrome with remote debugging enabled

Run `./scripts/launch-chrome.sh`, or manually, like so:

```sh
# Set up user data directory
USER_DATA_DIR="${HOME}/.chrome-claude-devcontainer"
mkdir -p "$USER_DATA_DIR"

# Launch Chrome with debugging enabled
"$CHROME_PATH" \
  --remote-debugging-port=9222 \
  --disable-extensions \
  --ignore-certificate-errors \
  --ignore-certificate-errors-spki-list \
  --allow-insecure-localhost \
  --disable-web-security \
  --disable-features=IsolateOrigins,site-per-process \
  --user-data-dir="$USER_DATA_DIR" \
  --no-first-run \
  --no-default-browser-check
```

## Troubleshooting

### Container won't start

**Problem**: Docker errors or container fails to build

**Solutions**:

- Ensure Docker Desktop is running
- Check Docker has enough disk space (3-5GB needed)
- Try rebuilding: Command Palette → "Dev Containers: Rebuild Container"

### Chrome DevTools connection fails

**Problem**: MCP can't connect to Chrome, "connection refused" errors

**Solutions**:

- Verify Chrome is running with debugging: `./scripts/launch-chrome.sh`
- Check if port 9222 is accessible: `curl http://localhost:9222/json` (on host)
- Restart the container to reinitialize the socat proxy
- Check socat logs: `cat /tmp/chrome-proxy.log` (inside container)

### Claude authentication issues

**Problem**: "Not logged in" errors inside container

**Solutions:**

- Authenticate on your host: `npx @anthropic-ai/claude-code login`
- Restart container to pick up credentials
- Note: macOS keychain credentials won't sync; use `--use-credential-file` on host if needed

**or, if you're not mounting ~/.claude**

- Authenticate inside the container: `npx @anthropic-ai/claude-code login`
- Credentials persist in the container's Docker volume

### Permission denied errors

**Problem**: Can't edit files created by the container on host

**Solutions**:

- Ensure your host user has write permissions to the project directory
- On Linux, the `node` user (uid 1000) should match your host user
- If needed, adjust file ownership: `sudo chown -R $(whoami) .`

---

## Advanced Usage

### Running without VS Code

You can use the devcontainer without VS Code:

```sh
./scripts/claude
```

That detects if you're in a container, and if not, will do one of:

```sh
# Start the container
npx @devcontainers/cli up --workspace-folder .

# Run Claude inside
./scripts/claude

# Or exec directly
npx @devcontainers/cli exec --workspace-folder . claude --dangerously-skip-permissions
```

You an also still use regular old `claude` on the host and ignore this entire setup.

### Accessing the container shell

```sh
# From host
npx @devcontainers/cli exec --workspace-folder . zsh

# Or from VS Code
# Just open a new terminal (it opens inside the container)
```

### Adding packages to the container

Edit `.devcontainer/Dockerfile` to add/edit packages you want to install, then rebuild the container in VS Code:

**Python**:

```dockerfile
RUN apt-get update && apt-get install -y python3 python3-pip
```

**Rust**:

```dockerfile
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/home/node/.cargo/bin:${PATH}"
```

**Go**:

```dockerfile
RUN wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
```

## License

MIT License - see [LICENSE](LICENSE) file for details. Use of Anthropic's
[.devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer) config is subject to their [Terms of
Service](https://www.anthropic.com/legal/commercial-terms).

## Acknowledgments

- Based on concepts from [Anthropic's Claude Code devcontainer reference](https://github.com/anthropics/claude-code)
- Uses [chrome-devtools-mcp](https://github.com/modelcontextprotocol/servers) for browser automation
- Inspired by the need for safe AI agent execution environments
