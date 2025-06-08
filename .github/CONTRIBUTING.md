# Contributing to Discogs Swift SDK

First off, thank you for considering contributing to the Discogs Swift SDK! It's people like you that make this project such a great tool for the Swift community.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Guidelines](#documentation-guidelines)
- [Release Process](#release-process)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

### Prerequisites

- **Xcode**: 15.0 or later
- **Swift**: 6.1 or later
- **Git**: Latest version
- **GitHub Account**: For submitting pull requests

### First Time Setup

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Discogs.git
   cd Discogs
   ```
3. **Add the original repository** as a remote:
   ```bash
   git remote add upstream https://github.com/briannadoubt/Discogs.git
   ```
4. **Install development dependencies** (if any):
   ```bash
   # Currently, this project has zero external dependencies
   swift package resolve
   ```
5. **Run the test suite** to ensure everything works:
   ```bash
   swift test
   ```

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check the [issue list](https://github.com/briannadoubt/Discogs/issues) to see if the problem has already been reported.

When you create a bug report, please include:

- **Clear, descriptive title**
- **Detailed description** of the issue
- **Steps to reproduce** the behavior
- **Expected vs actual behavior**
- **Environment details** (OS, Xcode version, Swift version)
- **Code samples** or minimal reproduction case
- **Stack traces** or error messages

Use the bug report template when creating new issues.

### 💡 Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Clear, descriptive title**
- **Detailed description** of the enhancement
- **Use cases** where this would be beneficial
- **Possible implementation** approach (if you have ideas)
- **Examples** of how the API would look

### 🔧 Code Contributions

1. **Find an issue** to work on or create a new one
2. **Comment on the issue** to let others know you're working on it
3. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make your changes** following our style guidelines
5. **Add tests** for your changes
6. **Ensure all tests pass**
7. **Submit a pull request**

## Development Setup

### Building the Project

```bash
# Build for all platforms
swift build

# Build for specific platform
swift build -c release
```

### Running Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter DiscogsTests

# Run with live API testing (requires DISCOGS_API_TOKEN)
DISCOGS_API_TOKEN=your_token swift test
```

### Code Generation

If you modify models or add new endpoints:

```bash
# Regenerate documentation
swift package generate-documentation

# Format code (if using SwiftFormat)
swiftformat .
```

## Pull Request Process

### Before Submitting

- [ ] **Rebase** your branch on the latest `main`
- [ ] **Run the full test suite** and ensure all tests pass
- [ ] **Add tests** for new functionality
- [ ] **Update documentation** if needed
- [ ] **Follow the code style** guidelines
- [ ] **Write clear commit messages**

### Pull Request Guidelines

1. **Use a clear, descriptive title**
2. **Reference any related issues** (`Fixes #123`, `Closes #456`)
3. **Describe your changes** in detail
4. **Include testing information**
5. **Add screenshots** for UI changes (if applicable)
6. **Keep PRs focused** - one feature/fix per PR

### PR Template

```markdown
## Description
Brief description of the changes.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Live API tests pass (if applicable)
- [ ] Manual testing completed

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
```

## Style Guidelines

### Swift Code Style

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) and use SwiftLint for consistency.

#### Key Points

- **Use clear, descriptive names** for functions, variables, and types
- **Prefer full words** over abbreviations
- **Use camelCase** for functions and variables
- **Use PascalCase** for types and protocols
- **Include documentation comments** for public APIs
- **Follow async/await patterns** for asynchronous code
- **Use actors** for thread-safe state management

#### Example

```swift
/// Retrieves a release from the Discogs database.
/// - Parameter id: The unique identifier for the release
/// - Returns: The release information
/// - Throws: `DiscogsError` if the request fails
public func getRelease(id: Int) async throws -> Release {
    let endpoint = DatabaseEndpoint.release(id: id)
    return try await httpClient.request(endpoint)
}
```

### Documentation Style

- **Use Swift documentation comments** (`///`) for all public APIs
- **Include parameter descriptions** for all parameters
- **Document return values** and thrown errors
- **Provide usage examples** for complex APIs
- **Keep descriptions concise** but complete

### Git Commit Messages

- **Use present tense** ("Add feature" not "Added feature")
- **Use imperative mood** ("Move cursor to..." not "Moves cursor to...")
- **Limit first line to 72 characters**
- **Reference issues and pull requests** when applicable
- **Include breaking change notes** in the commit body if applicable

#### Examples

```
Add marketplace listing search functionality

- Implement MarketplaceService.search() method
- Add SearchParameters model for filtering
- Include comprehensive unit tests
- Update documentation with usage examples

Fixes #123
```

## Testing Guidelines

### Test Structure

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test service interactions
- **Live API Tests**: Test against actual Discogs API (optional)
- **Mock Tests**: Test with simulated network responses

### Test Requirements

- **All new code must have tests**
- **Maintain or improve test coverage**
- **Use descriptive test names**
- **Follow AAA pattern** (Arrange, Act, Assert)
- **Test both success and failure cases**

### Example Test

```swift
func testGetReleaseSuccess() async throws {
    // Arrange
    let expectedRelease = Release(id: 123, title: "Test Album")
    mockHTTPClient.mockResponse = expectedRelease
    
    // Act
    let result = try await databaseService.getRelease(id: 123)
    
    // Assert
    XCTAssertEqual(result.id, 123)
    XCTAssertEqual(result.title, "Test Album")
}
```

## Documentation Guidelines

### API Documentation

- **Document all public APIs** with comprehensive comments
- **Include usage examples** for complex functionality
- **Provide parameter descriptions** for all parameters
- **Document error conditions** and recovery strategies
- **Keep documentation up to date** with code changes

### README Updates

- **Update feature lists** when adding new functionality
- **Add examples** for new APIs
- **Update compatibility information** when changing requirements
- **Keep installation instructions** current

## Release Process

### Version Numbers

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

1. **Update version numbers** in Package.swift
2. **Update CHANGELOG.md** with new version
3. **Run full test suite** on all platforms
4. **Update documentation** if needed
5. **Create GitHub release** with release notes
6. **Tag the release** with version number

## Questions?

If you have questions about contributing:

- **Check existing issues** and discussions
- **Create a discussion** on GitHub
- **Reach out** to maintainers
- **Join our community** channels

## Recognition

Contributors will be recognized in:
- **CONTRIBUTORS.md** file
- **Release notes** for their contributions
- **GitHub contributors** section

Thank you for contributing to Discogs Swift SDK! 🎵
