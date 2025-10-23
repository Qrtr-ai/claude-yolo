#!/bin/bash
set -e  # Exit on any error
set -u  # Exit on undefined variables

# Configuration
DEFAULT_BRANCH="main"
REPO_OWNER="Qrtr-ai"
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

# Check if script is running from a pipe (e.g., curl | sh)
is_piped() {
    [ ! -t 0 ]
}

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
                    printf "%b\n" "${RED}Error: --branch requires an argument${NC}"
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
                printf "%b\n" "${RED}Error: Unknown option $1${NC}"
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
    curl -fsSL https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/install.sh | sh

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
        printf "%b\n" "${RED}Error: Neither curl nor wget found${NC}"
        echo "Please install curl or wget and try again"
        exit 1
    fi

    # Check write permission in current directory
    if ! touch .write-test 2>/dev/null; then
        printf "%b\n" "${RED}Error: No write permission in current directory${NC}"
        echo "Please run this script from a directory where you have write access"
        exit 1
    fi
    rm -f .write-test

    printf "%b\n" "${GREEN}✓${NC} Prerequisites check passed"
    echo ""
}

# Detect and configure download tool
detect_downloader() {
    if command -v curl &> /dev/null; then
        DOWNLOADER="curl"
        DOWNLOAD_CMD="curl -fsSL"
        printf "%b\n" "${GREEN}✓${NC} Using curl for downloads"
    elif command -v wget &> /dev/null; then
        DOWNLOADER="wget"
        DOWNLOAD_CMD="wget -qO-"
        printf "%b\n" "${GREEN}✓${NC} Using wget for downloads"
    else
        printf "%b\n" "${RED}Error: No download tool found${NC}"
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
        printf "%b\n" "${YELLOW}Warning: The following files already exist:${NC}"
        for file in "${existing_files[@]}"; do
            echo "  - $file"
        done
        echo ""

        if [ "$FORCE" = false ]; then
            printf "%b\n" "${RED}Error: Files already exist. Use --force to overwrite.${NC}"
            printf "\n"
            if is_piped; then
                printf "%b\n" "${RED}Force install directly from the repository with:${NC}"
                printf "\n"
                printf "%b\n" "${RED}curl -fsSL https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/install.sh | sh -s -- --force${NC}"
            fi
            exit 1
        else
            printf "%b\n" "${YELLOW}Using --force flag, will overwrite existing files${NC}"
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
            printf "%b\n" "${GREEN}✓${NC} Created directory: $dir"
        fi

        # Download file
        local url="${BASE_URL}/${BRANCH}/${file}"
        echo "  Downloading $file..."

        if download_file "$url" "$file"; then
            printf "%b\n" "${GREEN}✓${NC} Installed: $file"
        else
            printf "%b\n" "${RED}✗${NC} Failed: $file"
            failed_files+=("$file")
        fi
    done

    echo ""

    # Check if any downloads failed
    if [ ${#failed_files[@]} -gt 0 ]; then
        printf "%b\n" "${RED}Error: Failed to download the following files:${NC}"
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
            printf "%b\n" "${GREEN}✓${NC} Made executable: $script"
        fi
    done

    echo ""
}

# Print success message with next steps
print_success() {
    printf "%b\n" "${GREEN}✓ claude-yolo installed successfully!${NC}"
    echo ""
    echo "Files installed:"
    for file in "${FILES[@]}"; do
        echo "  ✓ $file"
    done
    echo ""
    echo "Next steps:"
    echo "  1. Run ./scripts/launch-chrome.sh on your host machine"
    echo "  2. Configure MCP in ~/.claude/.mcp.json (see README for details)"
    echo "  3. Run claude in Claude devcontainer to run claude with full permissions"
    echo ""
    echo "Documentation: https://github.com/${REPO_OWNER}/${REPO_NAME}"
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
    print_success
}

main "$@"
