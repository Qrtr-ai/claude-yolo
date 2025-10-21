# Contributing to Claude YOLO

Thank you for your interest in contributing to Claude YOLO! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Issues

If you encounter a bug or have a suggestion:

1. Check if the issue already exists in [GitHub Issues](https://github.com/yourusername/claude-yolo/issues)
2. If not, create a new issue with:
   - A clear, descriptive title
   - Detailed description of the problem or suggestion
   - Steps to reproduce (for bugs)
   - Your environment (OS, Docker version, etc.)
   - Any relevant logs or error messages

### Pull Requests

1. **Fork the repository** and create a new branch from `main`
2. **Make your changes**:
   - Follow the existing code style
   - Test your changes thoroughly
   - Update documentation if needed
3. **Commit your changes**:
   - Use clear, descriptive commit messages
   - Reference any related issues
4. **Submit a pull request**:
   - Describe what your changes do and why
   - Link to any related issues

## Development Setup

To work on Claude YOLO itself:

1. Clone your fork:
   ```bash
   git clone https://github.com/yourusername/claude-yolo.git
   cd claude-yolo
   ```

2. Make your changes to:
   - `.devcontainer/Dockerfile` - Container image configuration
   - `.devcontainer/devcontainer.json` - VS Code devcontainer settings
   - `scripts/claude` - Claude wrapper script
   - `scripts/launch-chrome.sh` - Chrome launcher script
   - `README.md` - Documentation

3. Test your changes:
   - Rebuild the container: Command Palette → "Dev Containers: Rebuild Container"
   - Test the `./scripts/claude` script
   - Test the Chrome integration with `./scripts/launch-chrome.sh`
   - Verify all documentation is accurate

## Areas for Contribution

We welcome contributions in these areas:

### Documentation
- Improve installation instructions
- Add troubleshooting tips
- Create video tutorials or guides
- Translate documentation

### Features
- Support for additional MCP servers
- Improved platform detection (especially Windows/WSL)
- Performance optimizations
- Additional development tools in the container

### Testing
- Create automated tests for the setup
- Test on different platforms
- Validate with different Docker configurations

### Bug Fixes
- Fix platform-specific issues
- Improve error messages
- Handle edge cases

## Code Style

- **Shell scripts**: Use `#!/bin/bash` shebang, 2-space indentation
- **JSON**: 2-space indentation, no trailing commas
- **Markdown**: Follow [CommonMark](https://commonmark.org/) spec
- **Docker**: Follow [Dockerfile best practices](https://docs.docker.com/develop/dev-best-practices/)

## Testing Checklist

Before submitting a PR, verify:

- [ ] Container builds successfully on your platform
- [ ] `./scripts/claude` works both inside and outside container
- [ ] Chrome DevTools integration works (if modified)
- [ ] Documentation is updated and accurate
- [ ] No hardcoded paths or personal information
- [ ] Changes work on macOS, Linux, or Windows (if applicable)

## License

By contributing to Claude YOLO, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to open an issue with the `question` label if you have any questions about contributing!
