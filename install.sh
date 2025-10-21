#!/bin/bash
set -e  # Exit on any error
set -u  # Exit on undefined variables

# Configuration
DEFAULT_BRANCH="main"
REPO_OWNER="gert-verhoog"
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

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."

    # Check for curl or wget
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        echo -e "${RED}Error: Neither curl nor wget found${NC}"
        echo "Please install curl or wget and try again"
        exit 1
    fi

    # Check write permission in current directory
    if ! touch .write-test 2>/dev/null; then
        echo -e "${RED}Error: No write permission in current directory${NC}"
        echo "Please run this script from a directory where you have write access"
        exit 1
    fi
    rm -f .write-test

    echo -e "${GREEN}✓${NC} Prerequisites check passed"
    echo ""
}

# Detect and configure download tool
detect_downloader() {
    if command -v curl &> /dev/null; then
        DOWNLOADER="curl"
        DOWNLOAD_CMD="curl -fsSL"
        echo -e "${GREEN}✓${NC} Using curl for downloads"
    elif command -v wget &> /dev/null; then
        DOWNLOADER="wget"
        DOWNLOAD_CMD="wget -qO-"
        echo -e "${GREEN}✓${NC} Using wget for downloads"
    else
        echo -e "${RED}Error: No download tool found${NC}"
        exit 1
    fi
    echo ""
}

# Download a single file
download_file() {
    local url="$1"
    local output="$2"

    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL "$url" -o "$output"
    else
        wget -qO "$output" "$url"
    fi
}

# Check if files already exist
check_existing_files() {
    local existing_files=()

    for file in "${FILES[@]}"; do
        if [ -f "$file" ]; then
            existing_files+=("$file")
        fi
    done

    if [ ${#existing_files[@]} -gt 0 ]; then
        echo -e "${YELLOW}Warning: The following files already exist:${NC}"
        for file in "${existing_files[@]}"; do
            echo "  - $file"
        done
        echo ""

        if [ "$FORCE" = false ]; then
            echo -e "${RED}Error: Files already exist. Use --force to overwrite.${NC}"
            exit 1
        else
            echo -e "${YELLOW}Using --force flag, will overwrite existing files${NC}"
            echo ""
        fi
    fi
}

# Install files from repository
install_files() {
    echo "Installing files..."
    echo ""

    local failed_files=()

    for file in "${FILES[@]}"; do
        # Create directory if needed
        local dir=$(dirname "$file")
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo -e "${GREEN}✓${NC} Created directory: $dir"
        fi

        # Download file
        local url="${BASE_URL}/${BRANCH}/${file}"
        echo "  Downloading $file..."

        if download_file "$url" "$file"; then
            echo -e "${GREEN}✓${NC} Installed: $file"
        else
            echo -e "${RED}✗${NC} Failed: $file"
            failed_files+=("$file")
        fi
    done

    echo ""

    # Check if any downloads failed
    if [ ${#failed_files[@]} -gt 0 ]; then
        echo -e "${RED}Error: Failed to download the following files:${NC}"
        for file in "${failed_files[@]}"; do
            echo "  - $file"
        done
        echo ""
        echo "Please check your internet connection and try again."
        cleanup_on_error
        exit 1
    fi
}

# Clean up partial installation on error
cleanup_on_error() {
    echo "Cleaning up partial installation..."
    for file in "${FILES[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
        fi
    done

    # Remove empty directories
    rmdir .devcontainer 2>/dev/null || true
    rmdir scripts 2>/dev/null || true
}

# Set executable permissions on scripts
set_permissions() {
    echo "Setting permissions..."

    local scripts=(
        "scripts/claude"
        "scripts/launch-chrome.sh"
    )

    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            chmod +x "$script"
            echo -e "${GREEN}✓${NC} Made executable: $script"
        fi
    done

    echo ""
}

# Main execution
main() {
    parse_args "$@"

    echo "claude-yolo installer"
    echo "-------------------"
    echo "Branch: $BRANCH"
    echo ""

    check_prerequisites
    detect_downloader
    check_existing_files
    install_files
    set_permissions
}

main "$@"
