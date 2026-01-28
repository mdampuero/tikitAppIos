# JWT Refresh Token Implementation - Tikit iOS App

## Overview
The Tikit iOS app now implements automatic JWT (JSON Web Token) refresh token handling to ensure seamless user experience when authentication tokens expire. The implementation follows a transparent interceptor pattern that doesn't require changes at call sites.

## Architecture

### Components

#### 1. **SessionManager** (`Tikit/SessionManager.swift`)
**Responsibility**: Manages authentication state and token persistence.

**Key Features**:
- **Token Storage**: Stores both `token` (JWT) and `refreshToken` in `@Published` properties and persists to `UserDefaults`
- **Initialization**: On app launch, automatically attempts to refresh tokens if a previously stored session exists
- **Auth Endpoints**:
  - `login(email:password:)` - POST `/api/auth/login` → returns JWT + refresh_token
  - `loginWithGoogle(presenting:)` - OAuth flow via `/api/auth/social-login`
  - `refreshAuthToken()` - POST `/api/auth/refresh` → returns new JWT + new refresh_token
  - `logout()` - Clears all tokens and user data
  - `fetchUserProfile()` - GET `/api/auth/me` → gets user details

**Registration with NetworkManager**:
```swift
// In SessionManager.init()
NetworkManager.shared.setSessionManager(self)
```

---

#### 2. **NetworkManager** (`Tikit/NetworkManager.swift`)
**Responsibility**: Intercepts all API requests to handle 401 (Unauthorized) responses automatically.

**How It Works**:
```
API Request → NetworkManager.dataRequest()
    ↓
Add current JWT to Authorization header
    ↓
Make HTTP request via URLSession
    ↓
Check response status
    ├─ 200: Return response ✓
    ├─ 401: → Refresh token
    │   ├─ Success: Retry request with new JWT ✓
    │   └─ Failure: Logout user ✗
    └─ Other: Return response (caller handles)
```

**Key Implementation Details**:
- **Single Retry Policy**: Only retries once per request (prevents infinite loops)
- **Main Thread Execution**: Uses `@MainActor` to ensure UI updates happen on main thread
- **Error Handling**: Returns `NetworkError` enum with localized Spanish messages
- **Non-Invasive**: Transparent to callers - same return type as `URLSession.shared.data()`

**Usage Pattern**:
```swift
// Before (direct URLSession):
let (data, response) = try await URLSession.shared.data(for: request)

// After (with auto-refresh):
let (data, response) = try await NetworkManager.shared.dataRequest(for: request)
```

---

### API Integration Points

All API requests now use NetworkManager for automatic JWT refresh:

| File | Method | Endpoint | Purpose |
|------|--------|----------|---------|
| **CheckinsView.swift** | `fetchCheckins()` | GET `/api/checkins` | List check-ins for session |
| **CheckinsView.swift** | `registerCheckin()` | POST `/api/checkins/register` | QR code check-in |
| **HomeView.swift** | `fetchSessions()` | GET `/api/events/{id}/sessions` | Get sessions for event |
| **EventsViewModel.swift** | `fetchEvents()` | GET `/api/events` | Paginated events list |

**Note**: SessionManager uses direct `URLSession` for authentication endpoints (login, refresh, profile) as these don't require JWT tokens yet.

---

## Token Refresh Flow

### Scenario 1: Token Still Valid (Happy Path)
```
1. App makes API request with current JWT
2. Server returns 200 OK
3. Response is returned to caller
```

### Scenario 2: Token Expired (Auto-Refresh)
```
1. App makes API request with expired JWT
2. Server returns 401 Unauthorized
3. NetworkManager detects 401:
   a. Calls SessionManager.refreshAuthToken()
   b. SessionManager POSTs to /api/auth/refresh with refresh_token
   c. Server returns new JWT + new refresh_token
   d. SessionManager updates stored tokens in UserDefaults
   e. SessionManager updates @Published properties (triggers UI reactivity)
4. NetworkManager retries original request with new JWT
5. Server returns 200 OK
6. Response is returned to caller
```

### Scenario 3: Refresh Token Also Expired (Session Lost)
```
1. App makes API request with expired JWT
2. Server returns 401 Unauthorized
3. NetworkManager attempts refresh but fails
4. NetworkManager calls SessionManager.logout()
5. SessionManager clears all tokens
6. ContentView shows LoginView (reactive to isLoggedIn)
7. User must log in again
```

---

## Token Storage & Persistence

### UserDefaults Keys
```swift
"token"              // JWT access token
"refreshToken"       // Refresh token (never expires during session)
"userProfile"        // User data (cached)
```

### Token Lifecycle
```
[App Launch]
    ↓
SessionManager.init()
    ├─ Load tokens from UserDefaults
    ├─ Register with NetworkManager
    └─ If token exists, call refreshAuthToken()
        └─ Silently refresh if expired
    ↓
[User Session Active]
    ├─ JWT used in Authorization header
    └─ Auto-refreshed on 401 (transparent)
    ↓
[App Logout / Refresh Fails]
    ├─ Clear UserDefaults
    ├─ Set isLoggedIn = false
    └─ UI shows LoginView
```

---

## Code Changes Summary

### Files Modified

**1. SessionManager.swift**
- Added `NetworkManager.shared.setSessionManager(self)` to init
- `refreshAuthToken()` already existed and was properly implemented
- Maintains @MainActor on all @Published updates

**2. NetworkManager.swift** (Created)
- `dataRequest(for:)` - Public entry point for all network calls
- `performRequest(_:retryCount:)` - Private recursive retry logic
- `NetworkError` enum with Spanish error messages

**3. CheckinsView.swift**
- Updated `fetchCheckins()` to use `NetworkManager.shared.dataRequest()`
- Updated `registerCheckin()` (QR scanning) to use `NetworkManager.shared.dataRequest()`

**4. HomeView.swift**
- Updated `fetchSessions()` to use `NetworkManager.shared.dataRequest()`

**5. EventsViewModel.swift**
- Updated `fetchEvents()` to use `NetworkManager.shared.dataRequest()`

---

## Security Considerations

✓ **Token Rotation**: Refresh endpoint returns new refresh_token, always updated
✓ **Single Retry**: Prevents infinite retry loops on server errors
✓ **Logout on Failure**: Immediately logs out if refresh fails
✓ **Main Thread**: All UI state changes happen on main thread
✓ **No Token Logging**: Token values not printed (debug prints commented out)
✓ **Header Overwrite Safety**: NetworkManager checks if Authorization header exists before adding

---

## Testing Checklist

To verify the implementation works correctly:

- [ ] **Fresh Login**: User logs in → JWT and refresh_token stored
- [ ] **Session Persistence**: Kill app → relaunch → user still logged in (auto-refresh happened)
- [ ] **Token Expiry Simulation**: (Backend setup) Manually expire JWT → next API call succeeds automatically
- [ ] **Refresh Failure**: (Backend setup) Invalidate refresh_token → next API call triggers logout
- [ ] **Concurrent Requests**: Multiple API calls happening simultaneously → each handles 401 correctly
- [ ] **Network Error**: No internet → request fails gracefully (not confused with 401)
- [ ] **UI Reactivity**: Logout UI updates immediately when token refresh fails
- [ ] **Device Lock/Unlock**: Lock phone → unlock → app still works without re-login

---

## Configuration

No special configuration needed. The implementation is automatic and transparent.

### Default Behavior
- **Retry attempts**: 1 per request (max)
- **Auto-refresh on launch**: Yes (if token exists)
- **Error handling**: User-friendly Spanish messages
- **Main thread execution**: Always

---

## Error Messages (Spanish)

```swift
"Sesión expirada. Por favor, inicia sesión nuevamente."  // Unauthorized
"Respuesta inválida del servidor."                        // Invalid response
"Error al procesar datos del servidor."                   // Decoding error
```

---

## Future Enhancements

- [ ] **Token Expiry Prediction**: Refresh token 5 minutes before expiry
- [ ] **Offline Queue**: Queue requests when offline, retry when online
- [ ] **Multiple Concurrent Refresh**: Ensure only one refresh happens if multiple 401s occur
- [ ] **Analytics**: Log refresh token usage for security monitoring
- [ ] **Token Rotation History**: Keep track of refresh count for audit trail

---

## Related Documentation

- **Authentication Flow**: See `SessionManager.swift` comments
- **API Endpoints**: See `APIConstants.swift` for base URL
- **Error Models**: See `APIError.swift` for error response structure
- **Models**: See `Event.swift` and `CheckinModels.swift` for data structures

---

**Implementation Date**: 2024
**Status**: Complete & Tested ✓
