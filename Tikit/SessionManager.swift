import SwiftUI
import GoogleSignIn

struct AuthResponse: Codable {
    let token: String
    let refreshToken: String
    let user: UserProfile?

    enum CodingKeys: String, CodingKey {
        case token
        case refreshToken = "refresh_token"
        case user
    }
}

struct UserProfile: Codable {
    let id: Int?
    let firstName: String?
    let lastName: String?
    let email: String?
    let phone: String?
    let company: String?
    let position: String?
    let country: String?
    let state: String?
    let role: String?
    let imageUrl: String?
}

class SessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var token: String?
    @Published var refreshToken: String?
    @Published var user: UserProfile?

    private let tokenKey = "token"
    private let refreshTokenKey = "refreshToken"
    private let userKey = "userProfile"

    init() {
        token = UserDefaults.standard.string(forKey: tokenKey)
        refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)
        if let data = UserDefaults.standard.data(forKey: userKey),
           let storedUser = try? JSONDecoder().decode(UserProfile.self, from: data) {
            user = storedUser
        }
        isLoggedIn = token != nil
        
        // Registrar este SessionManager en el NetworkManager
        NetworkManager.shared.setSessionManager(self)
        
        if isLoggedIn {
            Task {
                _ = await refreshAuthToken()
            }
        }
    }

    @MainActor
    func login(email: String, password: String) async -> APIErrorResponse? {
        guard let url = URL(string: APIConstants.baseURL + "auth/login") else {
            return APIErrorResponse(message: "URL inválida", errors: nil)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                // print("Login status: \(http.statusCode)")
            }
            if let bodyString = String(data: data, encoding: .utf8) {
                // print("Login response: \(bodyString)")
            }
            guard let http = response as? HTTPURLResponse else {
                return APIErrorResponse(message: "Error del servidor", errors: nil)
            }
            if http.statusCode == 200 {
                let auth = try JSONDecoder().decode(AuthResponse.self, from: data)
                token = auth.token
                refreshToken = auth.refreshToken
                UserDefaults.standard.set(auth.token, forKey: tokenKey)
                UserDefaults.standard.set(auth.refreshToken, forKey: refreshTokenKey)
                isLoggedIn = true
                if let profile = auth.user {
                    user = profile
                    if let encoded = try? JSONEncoder().encode(profile) {
                        UserDefaults.standard.set(encoded, forKey: userKey)
                    }
                } else {
                    await fetchUserProfile()
                }
                return nil
            } else {
                if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    return apiError
                } else {
                    return APIErrorResponse(message: "Error del servidor", errors: nil)
                }
            }
        } catch {
            // print("Login error: \(error.localizedDescription)")
            return APIErrorResponse(message: error.localizedDescription, errors: nil)
        }
    }

    /// Refresh the access token using the stored refresh token.
    @MainActor
    func refreshAuthToken() async -> Bool {
        guard let refreshToken = refreshToken,
              let url = URL(string: APIConstants.baseURL + "auth/refresh") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["refresh_token": refreshToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return false
            }
            let auth = try JSONDecoder().decode(AuthResponse.self, from: data)
            token = auth.token
            self.refreshToken = auth.refreshToken
            UserDefaults.standard.set(auth.token, forKey: tokenKey)
            UserDefaults.standard.set(auth.refreshToken, forKey: refreshTokenKey)
            await fetchUserProfile()
            return true
        } catch {
            return false
        }
    }

    @MainActor
    func loginWithGoogle(presenting: UIViewController) async -> String? {
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
            // Usar accessToken en lugar de idToken
            let googleToken = result.user.accessToken.tokenString
            // print("DEBUG: Google accessToken: \(googleToken)")
            return await socialLogin(token: googleToken)
        } catch {
            return error.localizedDescription
        }
    }

    @MainActor
    private func socialLogin(token: String) async -> String? {
        guard let url = URL(string: APIConstants.baseURL + "auth/social-login") else { return "URL inválida" }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["provider": "google", "token": token]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // Debug: Imprimir lo que se envía
        if let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
            // print("DEBUG: socialLogin request body: \(bodyString)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Debug: Imprimir respuesta
            if let responseString = String(data: data, encoding: .utf8) {
                // print("DEBUG: socialLogin response: \(responseString)")
            }
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                // print("DEBUG: socialLogin error status code: \(statusCode)")
                return "Error del servidor"
            }
            let auth = try JSONDecoder().decode(AuthResponse.self, from: data)
            self.token = auth.token
            self.refreshToken = auth.refreshToken
            UserDefaults.standard.set(auth.token, forKey: tokenKey)
            UserDefaults.standard.set(auth.refreshToken, forKey: refreshTokenKey)
            isLoggedIn = true
            if let profile = auth.user {
                user = profile
                if let encoded = try? JSONEncoder().encode(profile) {
                    UserDefaults.standard.set(encoded, forKey: userKey)
                }
            } else {
                await fetchUserProfile()
            }
            return nil
        } catch {
            // print("DEBUG: socialLogin catch error: \(error.localizedDescription)")
            return error.localizedDescription
        }
    }

    @MainActor
    func logout() {
        token = nil
        refreshToken = nil
        user = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        isLoggedIn = false
    }

    @MainActor
    func fetchUserProfile() async {
        guard let token = token,
              let url = URL(string: APIConstants.baseURL + "auth/me") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            user = profile
            if let encoded = try? JSONEncoder().encode(profile) {
                UserDefaults.standard.set(encoded, forKey: userKey)
            }
        } catch {
            // print("Profile error: \(error.localizedDescription)")
        }
    }
}
