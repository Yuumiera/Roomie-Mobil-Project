# Contributing to Roomie

First off, thank you for considering contributing to Roomie! It's people like you that make Roomie such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title**
* **Describe the exact steps which reproduce the problem**
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed after following the steps**
* **Explain which behavior you expected to see instead and why**
* **Include screenshots and animated GIFs** if possible
* **Include your environment details** (Flutter version, OS, device, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a step-by-step description of the suggested enhancement**
* **Provide specific examples to demonstrate the steps**
* **Describe the current behavior** and **explain which behavior you expected to see instead**
* **Explain why this enhancement would be useful**

### Pull Requests

* Fill in the required template
* Do not include issue numbers in the PR title
* Follow the Dart style guide
* Include thoughtfully-worded, well-structured tests
* Document new code based on the Documentation Style Guide
* End all files with a newline

## Development Process

### Setup Development Environment

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/roomie-mobil-project.git`
3. Install dependencies: `flutter pub get`
4. Create a branch: `git checkout -b feature/my-new-feature`

### Making Changes

1. Make your changes in your feature branch
2. Add or update tests as necessary
3. Ensure all tests pass: `flutter test`
4. Format your code: `flutter format .`
5. Analyze your code: `flutter analyze`
6. Commit your changes using a descriptive commit message

### Commit Message Guidelines

We follow the conventional commit format:

```
type(scope): subject

body

footer
```

**Types:**
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools

**Example:**
```
feat(messaging): add real-time message delivery status

Implemented read receipts and delivery confirmations for chat messages.
Messages now show sent, delivered, and read status indicators.

Closes #123
```

### Testing Guidelines

* Write unit tests for all new functionality
* Ensure existing tests still pass
* Aim for high code coverage (>80%)
* Test edge cases and error conditions

### Code Style

* Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
* Use meaningful variable and function names
* Keep functions small and focused
* Add comments for complex logic
* Use `const` constructors where possible
* Prefer `final` over `var` where applicable

### Documentation

* Update README.md if needed
* Add inline documentation for public APIs
* Include examples for complex features
* Update API documentation for any endpoint changes

## Project Structure

When adding new features, follow the existing project structure:

* **Screens** go in `lib/screens/`
* **Reusable widgets** go in `lib/widgets/`
* **Business logic** goes in `lib/services/`
* **Data models** go in `lib/models/`
* **Utilities** go in `lib/utils/`

## Questions?

Feel free to open an issue with your question or reach out to the maintainers.

Thank you for contributing! 🎉
