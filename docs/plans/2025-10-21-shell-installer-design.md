# Shell Script Installer Design for claude-yolo

**Date:** 2025-10-21
**Status:** Approved

## Overview

This design describes a shell script installer that allows users to add claude-yolo's devcontainer configuration to their existing projects with a single command.

## Goals

- **Single command installation:** Users run one command to get all necessary files
- **Current directory installation:** Files install in the user's current working directory
- **User ownership:** After installation, users own and can customize the files
- **Simplicity:** No dependencies beyond curl/wget and bash
- **Safety:** Graceful error handling and validation

## Non-Goals

- Plugin-based distribution (not suitable for infrastructure files)
- Interactive prompts (breaks `curl | sh` pattern)
- Automatic updates (users own files after install)

## Architecture

### Installation Flow

1. User navigates to their project directory
2. User runs: `curl -fsSL https://raw.githubusercontent.com/USERNAME/claude-yolo/main/install.sh | sh`
3. Script performs pre-flight checks (prerequisites, write permissions)
4. Script downloads 4 files from GitHub raw URLs
5. Script creates directories as needed and places files
6. Script sets executable permissions on shell scripts
7. Script displays success message with next steps

### Files to Install

```
.devcontainer/
  devcontainer.json    # VS Code devcontainer configuration
  Dockerfile           # Container image definition
scripts/
  claude               # Wrapper script for running Claude Code
  launch-chrome.sh     # Host-side Chrome launcher with debugging
```

## File Download Strategy

### Approach

Use curl or wget to fetch raw files directly from GitHub:

```bash
BASE_URL="https://raw.githubusercontent.com/USERNAME/claude-yolo/main"

# Download each file to its destination
curl -fsSL "$BASE_URL/.devcontainer/devcontainer.json" -o .devcontainer/devcontainer.json
curl -fsSL "$BASE_URL/.devcontainer/Dockerfile" -o .devcontainer/Dockerfile
curl -fsSL "$BASE_URL/scripts/claude" -o scripts/claude
curl -fsSL "$BASE_URL/scripts/launch-chrome.sh" -o scripts/launch-chrome.sh
```

### Downloader Detection

Support both curl and wget with automatic detection:

```bash
if command -v curl &> /dev/null; then
    DOWNLOADER="curl -fsSL"
elif command -v wget &> /dev/null; then
    DOWNLOADER="wget -qO-"
else
    echo "Error: Neither curl nor wget found"
    exit 1
fi
```

### Why This Approach

- No need to clone entire repository
- Works with any branch or tag (versioned installs possible)
- Universally available tools
- Simple implementation

## Error Handling

### Pre-flight Checks

1. **Write permission check:** Verify current directory is writable
2. **Existing installation check:** Exit if files already exist (unless --force used)
3. **Downloader availability:** Verify curl or wget is available

### During Installation

1. **Download failures:** Show clear error with failed URL
2. **Atomic installation:** Clean up partial installs on any failure
3. **Directory creation:** Create `.devcontainer/` and `scripts/` as needed

### Post-Installation

Success message with next steps:

```
✓ claude-yolo installed successfully!

Files installed:
  .devcontainer/devcontainer.json
  .devcontainer/Dockerfile
  scripts/claude (executable)
  scripts/launch-chrome.sh (executable)

Next steps:
  1. Run ./scripts/launch-chrome.sh on your host machine
  2. Configure MCP in ~/.claude/.mcp.json (see README)
  3. Run ./scripts/claude to start Claude Code in devcontainer

Documentation: https://github.com/USERNAME/claude-yolo
```

## Command-Line Interface

### Basic Usage

```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/claude-yolo/main/install.sh | sh
```

### Alternative (Inspect First)

```bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/claude-yolo/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

### Optional Flags

- `--force`: Overwrite existing files without error
- `--branch BRANCH`: Install from specific branch (default: main)
- `--help`: Display usage information

## Implementation Structure

```bash
#!/bin/bash
set -e  # Exit on any error
set -u  # Exit on undefined variables

# Configuration
DEFAULT_BRANCH="main"
REPO_OWNER="USERNAME"
REPO_NAME="claude-yolo"

# Functions
check_prerequisites()    # Verify curl/wget and write permissions
detect_downloader()      # Determine curl vs wget
check_existing_files()   # Warn if files already present
download_file()          # Download single file with validation
install_files()          # Main installation logic
set_permissions()        # Make scripts executable
print_success()          # Show next steps
cleanup_on_error()       # Remove partial installation on failure

# Main execution
main() {
    parse_args "$@"
    check_prerequisites
    detect_downloader
    check_existing_files
    install_files
    set_permissions
    print_success
}

main "$@"
```

## Testing Strategy

### Manual Testing Scenarios

1. Fresh install in empty directory
2. Install in directory with existing files (should fail)
3. Install with --force flag (should overwrite)
4. Simulate download failure (invalid URL)
5. Test on different systems (macOS, Linux)
6. Test with both curl and wget

### Pre-release Validation

1. Test raw GitHub URL works before announcing
2. Verify permissions are correctly set on scripts
3. Confirm success message displays correctly
4. Test that partial installations clean up on error

## Documentation Updates

### Main README

Add installation section:

```markdown
## Installation

Install claude-yolo in your existing project:

\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/claude-yolo/main/install.sh | sh
\`\`\`

Or inspect the script first:

\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/USERNAME/claude-yolo/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
\`\`\`
```

### Contributors Guide

Document how the installer works for future maintainers:

- Script location and purpose
- How to test changes locally
- Version tagging strategy for stable releases

## Future Enhancements (Out of Scope)

- Interactive configuration (timezone, Claude version)
- Update mechanism (check for newer versions)
- Uninstall script
- Template variables for customization during install

## Alternatives Considered

### GitHub Template Repository

**Rejected because:** Only works for new projects, doesn't help adding to existing ones.

### npx-based Scaffolding Tool

**Rejected because:** More complexity, npm registry distribution overhead, not significantly better for static file copying.

### Claude Code Plugin

**Rejected because:** Plugins extend Claude's functionality (commands, agents, skills), not suitable for project infrastructure files.

## Decision

Proceed with shell script installer approach for simplicity, universal compatibility, and alignment with "single command to put files in the right place" goal.
