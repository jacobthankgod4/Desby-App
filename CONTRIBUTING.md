# Contributing to Desby OS

Thank you for your interest in contributing to Desby OS! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Help others learn and grow

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Submit a pull request

## Development Setup

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed setup instructions.

## Making Changes

### Before You Start
- Check existing issues and pull requests
- Discuss major changes in an issue first
- Follow the coding standards

### Code Changes

1. **Create Feature Branch**
```bash
git checkout -b feat/your-feature-name
```

2. **Make Changes**
- Follow [CODING_STANDARDS.md](CODING_STANDARDS.md)
- Write clear, descriptive commit messages
- Keep commits atomic and focused

3. **Write Tests**
- Add unit tests for new code
- Aim for > 70% coverage
- Test edge cases and error scenarios

4. **Update Documentation**
- Update README if needed
- Add code comments for complex logic
- Update CHANGELOG

5. **Run Quality Checks**
```bash
flutter analyze
dart format .
flutter test
```

## Commit Messages

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build, dependencies, or tooling

### Examples
```
feat(auth): add two-factor authentication

- Implement TOTP-based 2FA
- Add 2FA setup screen
- Add 2FA verification during login

Closes #123

fix(ui): fix button alignment on mobile

The button was misaligned on small screens due to
incorrect padding calculation.

Fixes #456

docs(readme): update installation instructions

Added step-by-step installation guide for macOS.
```

## Pull Request Process

### Before Submitting
1. Ensure all tests pass
2. Run code quality checks
3. Update documentation
4. Rebase on latest main

### PR Description
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issues
Closes #123

## Testing
Describe testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Changes are backward compatible
```

### Review Process
1. Automated checks must pass
2. Code review by maintainers
3. Address feedback
4. Approval and merge

## Testing Guidelines

### Unit Tests
```dart
void main() {
  group('FeatureName', () {
    test('should do something', () {
      // Arrange
      final input = 'test';
      
      // Act
      final result = function(input);
      
      // Assert
      expect(result, 'expected');
    });
  });
}
```

### Test Coverage
- Aim for > 70% coverage
- Test happy paths
- Test error cases
- Test edge cases

### Running Tests
```bash
# All tests
flutter test

# Specific file
flutter test test/core/error/error_handler_test.dart

# With coverage
flutter test --coverage
```

## Documentation

### Code Comments
- Explain "why", not "what"
- Use `///` for public APIs
- Keep comments up-to-date

### README Updates
- Update if adding new features
- Include setup instructions
- Add examples if applicable

### CHANGELOG
Add entry for significant changes:
```markdown
## [1.1.0] - 2024-01-15

### Added
- Two-factor authentication
- New design gallery

### Fixed
- Button alignment on mobile
- Memory leak in chat

### Changed
- Updated API endpoints
```

## Issue Reporting

### Bug Reports
Include:
- Description of the bug
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots/logs if applicable
- Environment (OS, Flutter version, etc.)

### Feature Requests
Include:
- Description of feature
- Use case/motivation
- Proposed implementation (optional)
- Related issues

## Code Review Checklist

Reviewers will check:
- [ ] Code follows style guidelines
- [ ] Tests are included
- [ ] Documentation is updated
- [ ] No performance issues
- [ ] Security best practices followed
- [ ] No breaking changes
- [ ] Commits are well-organized

## Merge Conflicts

If your PR has conflicts:
1. Update your branch: `git fetch origin`
2. Rebase: `git rebase origin/main`
3. Resolve conflicts
4. Force push: `git push origin feat/your-feature --force`

## Deployment

### Release Process
1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Create release branch
4. Tag release: `git tag v1.0.0`
5. Push tag: `git push origin v1.0.0`

### Versioning
Follow [Semantic Versioning](https://semver.org/):
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes

## Questions?

- Check [DEVELOPMENT.md](DEVELOPMENT.md)
- Check [CODING_STANDARDS.md](CODING_STANDARDS.md)
- Open an issue for discussion
- Contact maintainers

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md
- Release notes
- GitHub contributors page

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## Additional Resources

- [GitHub Flow Guide](https://guides.github.com/introduction/flow/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)

Thank you for contributing to Desby OS! 🎉
