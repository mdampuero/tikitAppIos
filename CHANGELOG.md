# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.5] - 2026-02-18

### Added
- Display app version number and build code on login screen for better error identification
  - Added `appVersion` property in LoginView that retrieves version from Bundle.main
  - Information appears below the "Validate Code" button in format `v1.x.x (build)`
- New session statistics screen on check-ins view
  - Statistics button in top bar (next to category filter)
  - Shows completed check-ins vs total registered
  - General attendance progress bar
  - Attendance breakdown by access category with progress bars
  - Session time information for temporary sessions
  - Accessible via modal similar to category filter

### Changed
- Unified colors according to official brandbook
  - Orange (#F26A35) as primary color
  - Purple (#5E38E2) as secondary color
  - Black (#151515) as background color
- Updated all gradients to transition from orange to purple
  - Applied in ProfileView and SessionStatisticsView
- All buttons now use purple color (brandSecondary) instead of orange
  - Includes validation, check-in, save, and category buttons
  - Access type badges in orange (brandPrimary)
- Successful check-in screen updated with brandbook colors
  - Main checkmark icon in green (success indicator)
  - Detail icons (person, email, ticket, etc.) in orange (brandPrimary)
  - Header background in green with low opacity
  - Close button in purple (brandSecondary)
- Session statistics screen now automatically refreshes data from API
  - Calls GET `/event-sessions/{code}` endpoint silently when view opens
  - Updates local UserDefaults with fresh session data
  - Shows real-time attendance and check-in statistics

### Deprecated

### Removed

### Fixed
- Fixed modal closure issue when opening statistics screen
  - Session data refresh no longer triggers notifications that close the modal
  - Added `updateTemporarySessionSilently()` method for background updates
  - Statistics view now updates data silently without affecting modal state
- Updated successful check-in icon color to green
  - Main checkmark icon is now green instead of orange
  - Header background changed from orange to green with low opacity

### Security

## [1.2.2] - 2026-02-XX

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

---

## Notes for future changes:
- **Added**: For new features
- **Changed**: For changes in existing features
- **Deprecated**: For features to be removed soon
- **Removed**: For removed features
- **Fixed**: For bug fixes
- **Security**: For security vulnerabilities
