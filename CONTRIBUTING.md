# Contributing to eShelf

Hướng dẫn đóng góp cho dự án eShelf.

## Development Workflow

### 1. Clone và Setup

```bash
git clone https://github.com/levanvux/eShelf.git
cd eShelf
npm run setup
```

### 2. Tạo Branch Mới

```bash
git checkout -b feature/your-feature-name
```

### 3. Commit Changes

```bash
git add .
git commit -m "feat: add new feature"
```

**Commit message format:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `style:` - Code style (formatting)
- `refactor:` - Code refactoring
- `test:` - Add tests
- `chore:` - Maintenance

### 4. Push và Create PR

```bash
git push origin feature/your-feature-name
```

Tạo Pull Request trên GitHub.

## Code Style

### Frontend
- Use functional components
- Use hooks (useState, useEffect, etc.)
- Follow TailwindCSS conventions
- Add PropTypes or TypeScript types

### Backend
- Use async/await
- Handle errors properly
- Add JSDoc comments
- Follow REST API conventions

## Testing

```bash
# Frontend
npm test

# Backend
cd backend/services/auth-service
npm test
```

## Before Submitting PR

- [ ] Code builds successfully
- [ ] Tests pass
- [ ] No linter errors
- [ ] Documentation updated
- [ ] Commit messages follow convention

## Questions?

Contact team lead or create an issue on GitHub.

