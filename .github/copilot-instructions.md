# Tikit iOS App - AI Coding Instructions

## Project Overview
Tikit is an iOS event management application built with SwiftUI. The app enables users to log in (via email/password or Google OAuth), view events, manage sessions, and check in guests using QR codes.

## Architecture & Data Flow

### Authentication Flow
- **Entry Point**: [TikitApp.swift](../Tikit/TikitApp.swift) - Initializes `SessionManager` as environment object
- **Session Management**: [SessionManager.swift](../Tikit/SessionManager.swift) handles:
  - Email/password login → `auth/login` endpoint
  - Google OAuth → `auth/social-login` endpoint  
  - Token refresh → `auth/refresh` endpoint
  - User profile persistence via `UserDefaults`
  - Uses `@Published` properties for reactive UI updates
- **Key Pattern**: JWT tokens stored in `UserDefaults` with refresh token strategy
- **Routing**: [ContentView.swift](../Tikit/ContentView.swift) shows `LoginView` or `MainView` based on `session.isLoggedIn` state

### UI Structure
- **Navigation**: Tab-based (`MainView` uses `TabView`) with two main sections:
  - "Eventos" → [HomeView.swift](../Tikit/HomeView.swift)
  - "Mi cuenta" → [ProfileView.swift](../Tikit/ProfileView.swift)
- **Views**: Each view receives `@EnvironmentObject var session: SessionManager` for token/user access

### Data Models & API Integration

**Key Models** (all `Codable`):
- [Event.swift](../Tikit/Event.swift): `Event`, `EventsResponse`, `Pagination`, `EventSession`
- [CheckinModels.swift](../Tikit/CheckinModels.swift): `CheckinResponse` with nested `Guest` and `EventSessionInfo`
- [SessionManager.swift](../Tikit/SessionManager.swift): `AuthResponse`, `UserProfile` (used by login responses)

**API Constants**: Base URL in [APIConstants.swift](../Tikit/APIConstants.swift) = `https://tikit.cl/api/`

**Error Handling**: [APIError.swift](../Tikit/APIError.swift) defines `APIErrorResponse` with:
- `message`: General error string
- `errors`: Dictionary of field-level validation errors (maps to `fieldErrors` computed property)

### ViewModels
- [EventsViewModel.swift](../Tikit/EventsViewModel.swift): Manages paginated event list fetch
  - `fetchEvents()` hits `/events?page=X&limit=10&order=id:DESC`
  - Implements `loadMoreIfNeeded()` for infinite scroll
  - Uses `Bearer {token}` authorization header

## Development Conventions

### Network Requests
- All API calls use `URLSession.shared.data(for:)` with async/await
- Authorization: Always add `"Authorization"` header with `"Bearer \(token)"` for authenticated endpoints
- Response parsing: Decode to typed structs immediately after status check
- Error responses checked for `statusCode == 200` before decoding success models
- **Debugging**: Print response JSON string for troubleshooting (seen in `login()`, `fetchEvents()`)

### SwiftUI Patterns
- Use `@EnvironmentObject` for app-wide session state
- Use `@Published` in `ObservableObject` classes for reactive updates
- Mark async methods with `@MainActor` to ensure UI updates on main thread
- Implement `.placeholder(when: condition)` modifier for TextField hints

### Coding Keys
Use explicit `CodingKeys` enums for API field mapping (e.g., `refreshToken = "refresh_token"`, `currentPage = "current_page"` in pagination)

### Colors & Assets
- [Colors.swift](../Tikit/Colors.swift) defines app color scheme
- Dark/Light mode assets in [Assets.xcassets](../Tikit/Assets.xcassets/) (LogoDark, LogoLight, GoogleIcon)

## Testing & Build

- Unit tests: [TikitTests/](../TikitTests/)
- UI tests: [TikitUITests/](../TikitUITests/)
- Project config: [Tikit.xcodeproj/project.pbxproj](../Tikit.xcodeproj/project.pbxproj)
- Entitlements: [Tikit.entitlements](../Tikit/Tikit.entitlements) - Configure for camera access (QR scanning) and Google Sign-In

## Integration Points

**Google Sign-In**: Requires `clientID = "331974773758-ms75sk3bv25vkfm0a7qao8ft0ur1kvep.apps.googleusercontent.com"` (hardcoded in `SessionManager.loginWithGoogle()`)

**Camera/QR Scanning**: [QRScannerView.swift](../Tikit/QRScannerView.swift), [ScanView.swift](../Tikit/ScanView.swift) - requires camera permission in entitlements

## Critical Patterns to Maintain

1. **Always decode `APIErrorResponse` on non-200 status** before returning generic errors
2. **Use snake_case in JSON** but map to camelCase in Swift models via `CodingKeys`
3. **Pass tokens through async chains** - viewmodels receive token as parameter, don't store it
4. **Session init refreshes token** - handles auto-refresh on app launch if previously logged in
5. **Pagination state** - `currentPage` and `totalPages` reset on `refresh()`, increment on `fetchEvents()`
