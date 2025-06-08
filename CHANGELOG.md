# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Enhanced async/await support throughout the codebase
- Improved error handling with more specific error types
- Additional platform examples for iOS, macOS, and server-side Swift
- Advanced configuration options for HTTP clients and caching
- Comprehensive logging and debugging capabilities
- Performance optimization guides
- Memory management best practices documentation

### Changed
- Updated Swift requirement to 6.1+
- Enhanced rate limiting with exponential backoff
- Improved test coverage to 95%+
- Better documentation with interactive examples

### Fixed
- Rate limiting edge cases
- Memory leaks in long-running applications
- Thread safety improvements with actors

## [1.0.0] - 2025-06-07

### Added
- **Complete Discogs API Coverage**
  - Database Service (releases, artists, labels, masters)
  - Search Service (releases, artists, labels)
  - Collection Service (user collections, folders, items)
  - Marketplace Service (listings, orders, fee calculations)
  - User Service (identity, profiles, submissions)
  - Wantlist Service (user wantlists, items)

- **Modern Swift Features**
  - Full async/await support
  - Actor-based concurrency for thread safety
  - Sendable protocol compliance
  - Swift 6.1 compatibility

- **Multi-Platform Support**
  - iOS 15.0+ support
  - macOS 12.0+ support
  - tvOS 15.0+ support
  - watchOS 8.0+ support
  - visionOS 1.0+ support
  - Linux Ubuntu 20.04+ support

- **Authentication**
  - Personal Access Token authentication
  - OAuth 1.0a authentication support
  - Secure token management

- **Rate Limiting & Performance**
  - Intelligent rate limiting with respect for API limits
  - Automatic retry mechanisms with exponential backoff
  - Request deduplication
  - Response caching support

- **Developer Experience**
  - Comprehensive error handling with detailed error types
  - Extensive documentation and code examples
  - Protocol-based architecture for testability
  - Mock implementations for testing
  - Dependency injection support

- **Quality Assurance**
  - 95%+ test coverage
  - Unit tests for all services and models
  - Integration tests with live API endpoints
  - Comprehensive CI/CD pipeline
  - Security auditing and vulnerability scanning
  - Code quality analysis with SwiftLint

- **Documentation**
  - Complete API reference documentation
  - Getting started guides
  - Platform-specific examples
  - Best practices documentation
  - Migration guides
  - Contributing guidelines

### Technical Details
- **Architecture**: Protocol-oriented design with dependency injection
- **Networking**: URLSession-based with custom HTTP client abstraction
- **Data Models**: Comprehensive Codable models for all API responses
- **Error Handling**: Structured error types with recovery suggestions
- **Testing**: Comprehensive test suite with mock and live API testing
- **CI/CD**: GitHub Actions workflow with multi-platform builds and testing

### API Endpoints Supported
- **Database API**: All endpoints for releases, artists, labels, and masters
- **Search API**: All search endpoints with filtering and pagination
- **Collection API**: Complete collection management functionality
- **Marketplace API**: Full marketplace integration including orders and fees
- **User API**: User identity, profiles, and submission history
- **Wantlist API**: Complete wantlist management

### Dependencies
- **External**: Zero external dependencies (Foundation only)
- **Internal**: Modular architecture with clear separation of concerns

---

## Release Process

This project follows semantic versioning:
- **Major version** (X.0.0): Breaking API changes
- **Minor version** (0.X.0): New features, backward compatible
- **Patch version** (0.0.X): Bug fixes, backward compatible

### Release Checklist
- [ ] Update version in Package.swift
- [ ] Update CHANGELOG.md
- [ ] Update README.md if needed
- [ ] Run full test suite
- [ ] Create GitHub release with notes
- [ ] Update documentation
- [ ] Announce on community channels
