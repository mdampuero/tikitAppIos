import SwiftUI
import GoogleSignIn

struct AuthResponse: Codable {
    let token: String
    let refreshToken: String
}

class SessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var token: String?
    @Published var refreshToken: String?

    private let tokenKey = "token"
    private let refreshTokenKey = "refreshToken"

    init() {
        token = UserDefaults.standard.string(forKey: tokenKey)
        refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)
        isLoggedIn = token != nil
    }

    @MainActor
    func login(email: String, password: String) async -> String? {
        guard let url = URL(string: "https://tikit.cl/api/auth/login") else { return "URL inválida" }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                print("Login status: \(http.statusCode)")
            }
            if let bodyString = String(data: data, encoding: .utf8) {
                print("Login response: \(bodyString)")
            }
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return "Error del servidor"
            }
            let auth = try JSONDecoder().decode(AuthResponse.self, from: data)
            token = auth.token
            refreshToken = auth.refreshToken
            UserDefaults.standard.set(auth.token, forKey: tokenKey)
            UserDefaults.standard.set(auth.refreshToken, forKey: refreshTokenKey)
            isLoggedIn = true
            return nil
        } catch {
            print("Login error: \(error.localizedDescription)")
            return error.localizedDescription
        }
    }

    /// Refresh the access token using the stored refresh token.
    @MainActor
    func refreshAuthToken() async -> Bool {
        guard let refreshToken = refreshToken,
              let url = URL(string: "https://tikit.cl/api/auth/refresh") else { return false }
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
            return true
        } catch {
            return false
        }
    }

    @MainActor
    func loginWithGoogle(presenting: UIViewController) async -> String? {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "331974773758-ms75sk3bv25vkfm0a7qao8ft0ur1kvep.apps.googleusercontent.com")
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
            let googleToken = result.user.idToken?.tokenString ?? ""
            return await socialLogin(token: googleToken)
        } catch {
            return error.localizedDescription
        }
    }

    @MainActor
    private func socialLogin(token: String) async -> String? {
        guard let url = URL(string: "https://tikit.cl/api/auth/social-login") else { return "URL inválida" }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["provider": "google", "token": token]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return "Error del servidor"
            }
            let auth = try JSONDecoder().decode(AuthResponse.self, from: data)
            self.token = auth.token
            self.refreshToken = auth.refreshToken
            UserDefaults.standard.set(auth.token, forKey: tokenKey)
            UserDefaults.standard.set(auth.refreshToken, forKey: refreshTokenKey)
            isLoggedIn = true
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
