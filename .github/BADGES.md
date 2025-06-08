# GitHub Actions Badges

Add these badges to your main README.md to show the status of your CI/CD pipeline:

## Status Badges

### CI Pipeline Status
```markdown
[![CI](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/ci.yml)
```

### Release Status
```markdown
[![Release](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/release.yml/badge.svg)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/release.yml)
```

### Security Status
```markdown
[![Security](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/security.yml/badge.svg)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/security.yml)
```

### All Badges Combined
```markdown
[![CI](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/ci.yml)
[![Release](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/release.yml/badge.svg)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/release.yml)
[![Security](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/security.yml/badge.svg)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/security.yml)
```

## Custom Badge Styles

### Flat Style
```markdown
[![CI](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/ci.yml/badge.svg?style=flat)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/ci.yml)
```

### For the Badge Style
```markdown
[![CI](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/ci.yml/badge.svg?style=for-the-badge)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/ci.yml)
```

## Platform Support Badges

```markdown
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-lightgrey)
![Swift](https://img.shields.io/badge/swift-6.1-orange)
![License](https://img.shields.io/badge/license-MIT-blue)
```

## Instructions

1. Replace `YOUR_USERNAME` with your actual GitHub username in all badge URLs
2. Copy the badges to your main README.md file
3. The badges will automatically show the status of your CI/CD workflows once your repository is public and workflows have run

## Badge Status Meanings

- **CI Badge**: Shows the status of the main CI pipeline (build, test, quality checks)
- **Release Badge**: Shows the status of the release workflow and latest release
- **Security Badge**: Shows the status of security audits and vulnerability scans

## Example for username "johndoe"

```markdown
[![CI](https://github.com/johndoe/Discogs/actions/workflows/ci.yml/badge.svg)](https://github.com/johndoe/Discogs/actions/workflows/ci.yml)
[![Release](https://github.com/johndoe/Discogs/actions/workflows/release.yml/badge.svg)](https://github.com/johndoe/Discogs/actions/workflows/release.yml)
[![Security](https://github.com/johndoe/Discogs/actions/workflows/security.yml/badge.svg)](https://github.com/johndoe/Discogs/actions/workflows/security.yml)
```
2. Add these badges to the top of your main README.md file
3. The badges will automatically update to reflect the current status of your workflows

## Example README Header

```markdown
# Discogs Swift Package

[![CI](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/ci.yml)
[![Release](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/release.yml/badge.svg)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/release.yml)
[![Security](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/security.yml/badge.svg)](https://github.com/YOUR_USERNAME/Discogs/actions/workflows/security.yml)

![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-lightgrey)
![Swift](https://img.shields.io/badge/swift-6.1-orange)

A comprehensive Swift package for the Discogs API with protocol-oriented architecture and full platform support.
```
