# Contributing to eShelf

Thank you for your interest in contributing to eShelf! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/votrung654/EShelf/issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Node.js version, etc.)
   - Screenshots if applicable

### Suggesting Features

1. Check existing [Issues](https://github.com/votrung654/EShelf/issues) for similar suggestions
2. Create a new issue with:
   - Clear description of the feature
   - Use case and benefits
   - Possible implementation approach (if you have ideas)

### Pull Requests

1. **Fork the repository**
   ```bash
   git clone https://github.com/votrung654/EShelf.git
   cd EShelf
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the coding standards (see below)
   - Write or update tests if applicable
   - Update documentation if needed

4. **Test your changes**
   ```bash
   # Run linting
   npm run lint
   
   # Test backend services
   cd backend
   docker-compose up -d
   docker-compose logs
   
   # Test frontend
   cd ..
   npm run dev
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```
   
   Use conventional commit messages:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `style:` - Code style changes (formatting, etc.)
   - `refactor:` - Code refactoring
   - `test:` - Adding or updating tests
   - `chore:` - Maintenance tasks

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Use the PR template
   - Describe your changes clearly
   - Reference related issues if any
   - Wait for code review

## Development Setup

### Prerequisites

- Node.js >= 20
- Python >= 3.11
- Docker & Docker Compose
- Git

### Setup Steps

1. **Clone and install dependencies**
   ```bash
   git clone https://github.com/votrung654/EShelf.git
   cd EShelf
   npm install
   ```

2. **Start backend services**
   ```bash
   cd backend
   docker-compose up -d
   ```

3. **Start frontend**
   ```bash
   cd ..
   npm run dev
   ```

4. **Run tests**
   ```bash
   npm run lint
   npm test  # if available
   ```

## Coding Standards

### JavaScript/TypeScript

- Use ESLint configuration provided in the project
- Follow existing code style
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

### Python

- Follow PEP 8 style guide
- Use type hints where applicable
- Add docstrings for functions and classes

### Git

- Write clear, descriptive commit messages
- Use conventional commits format
- Keep commits focused (one logical change per commit)
- Rebase your branch before creating PR

### Code Review

- Be respectful and constructive
- Focus on the code, not the person
- Explain your suggestions
- Be open to feedback

## Project Structure

```
eShelf/
├── backend/           # Backend services
│   ├── services/      # Microservices
│   └── database/      # Database setup
├── src/               # Frontend React app
├── infrastructure/    # IaC and deployment configs
├── docs/              # Documentation
└── scripts/           # Utility scripts
```

## Questions?

If you have questions, feel free to:
- Open an issue with the `question` label
- Check existing documentation in `docs/` directory

Thank you for contributing to eShelf! 🎉

