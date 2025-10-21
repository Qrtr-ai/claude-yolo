#!/bin/bash
set -e  # Exit on any error
set -u  # Exit on undefined variables

# Configuration
DEFAULT_BRANCH="main"
REPO_OWNER="USERNAME"  # TODO: Replace with actual GitHub username
REPO_NAME="claude-yolo"
BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}"

# Files to install
FILES=(
  ".devcontainer/devcontainer.json"
  ".devcontainer/Dockerfile"
  "scripts/claude"
  "scripts/launch-chrome.sh"
)

# Color output for better UX
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse command line arguments
parse_args() {
    FORCE=false
    BRANCH="$DEFAULT_BRANCH"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                FORCE=true
                shift
                ;;
            --branch)
                if [ -z "${2:-}" ]; then
                    echo -e "${RED}Error: --branch requires an argument${NC}"
                    show_help
                    exit 1
                fi
                BRANCH="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Error: Unknown option $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Install claude-yolo configuration files to the current directory.

OPTIONS:
    --force         Overwrite existing files without prompting
    --branch NAME   Install from specific branch (default: main)
    --help, -h      Show this help message

EXAMPLES:
    # Basic installation
    curl -fsSL https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/install.sh | bash

    # Install with force overwrite
    ./install.sh --force

    # Install from specific branch
    ./install.sh --branch develop

EOF
}

# Main execution
main() {
    parse_args "$@"

    echo "claude-yolo installer"
    echo "-------------------"
    echo "Branch: $BRANCH"
    echo ""
}

main "$@"
