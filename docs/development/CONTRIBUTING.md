# Contributing to Microsoft 365 Copilot Plugin Project

We welcome contributions to this project! This document provides guidelines for contributing.

## 🤝 How to Contribute

### 1. Fork the Repository

- Fork this repository to your GitHub account
- Clone your fork locally

### 2. Set Up Development Environment

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/copilot-plugin-project.git
cd copilot-plugin-project

# Install dependencies
pip install -r requirements.txt

# Install development dependencies
pip install pytest flake8 black isort mypy bandit safety

# Copy local settings
cp local.settings.json.template local.settings.json
```

### 3. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 4. Make Your Changes

- Follow the coding standards (see below)
- Add tests for new functionality
- Update documentation as needed
- Ensure all CI checks pass

### 5. Submit a Pull Request

- Push your branch to your fork
- Create a pull request against the main branch
- Provide a clear description of your changes

## 📝 Coding Standards

### Python Code Style

- **Formatting**: Use `black` for code formatting
- **Import Sorting**: Use `isort` for import organization
- **Linting**: Follow `flake8` rules
- **Type Hints**: Use type hints for function parameters and return values
- **Documentation**: Include docstrings for all public functions and classes

### Code Quality Checks

Run these commands before submitting:

```bash
# Format code
black src/ tests/

# Sort imports
isort src/ tests/

# Lint code
flake8 src/ tests/

# Type checking
mypy src/

# Security check
bandit -r src/

# Dependency check
safety check
```

### Testing Requirements

- **Unit Tests**: All new functions must have unit tests
- **Integration Tests**: API endpoints should have integration tests
- **Coverage**: Maintain >80% test coverage
- **Test Naming**: Use descriptive test names that explain what is being tested

### Documentation Standards

- **README Updates**: Update README.md for new features
- **API Documentation**: Update OpenAPI spec for API changes
- **Architecture Docs**: Update architecture.md for structural changes
- **Comments**: Use clear, concise comments for complex logic

## 🚦 CI/CD Pipeline

All pull requests must pass:

- **Linting**: Python code style checks
- **Testing**: Unit and integration tests
- **Security**: Security vulnerability scans
- **Plugin Validation**: OpenAPI and manifest validation
- **Type Checking**: MyPy type validation

## 🐛 Bug Reports

When reporting bugs, please include:

- **Description**: Clear description of the issue
- **Steps to Reproduce**: Detailed steps to reproduce the bug
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Environment**: OS, Python version, Azure CLI version
- **Logs**: Relevant error messages or logs

## 💡 Feature Requests

For new features:

- **Use Case**: Describe the problem you're trying to solve
- **Proposed Solution**: Outline your suggested approach
- **Alternatives**: Consider alternative approaches
- **Impact**: Estimate the impact on existing functionality

## 📋 Issue Labels

We use these labels to categorize issues:

- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Improvements or additions to documentation
- `good-first-issue`: Good for newcomers
- `help-wanted`: Extra attention is needed
- `security`: Security-related issues

## 🔒 Security

If you discover a security vulnerability:

- **Do NOT** open a public issue
- Email us directly at <security@company.com>
- Provide detailed information about the vulnerability
- Allow time for us to address the issue before public disclosure

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Recognition

Contributors will be recognized in:

- The project README
- Release notes for significant contributions
- Special recognition for major features or bug fixes

## ❓ Questions

If you have questions:

- Check existing issues and documentation
- Open a discussion in GitHub Discussions
- Contact the maintainers

Thank you for contributing to the Microsoft 365 Copilot Plugin Project!
