import Foundation

// MARK: - Modelos de respuesta de la API

struct SessionCodeResponse: Codable {
    let id: Int
    let name: String
    let description: String?
    let startDate: String
    let endDate: String
    let startTime: String
    let endTime: String
    let isDefault: Bool
    let createdAt: String
    let updatedAt: String
    let event: SessionEvent
    let registrantTypes: [SessionRegistrantType]
}

struct SessionEvent: Codable {
    let id: Int
    let name: String
    let type: String
}

// MARK: - Datos de sesión temporal guardados

struct TemporarySessionData: Codable {
    let sessionId: Int
    let sessionName: String
    let sessionCode: String
    let eventId: Int
    let eventName: String
    let expirationDate: Date
    let startDate: String
    let endDate: String
    let startTime: String
    let endTime: String
    let registrantTypes: [SessionRegistrantType]
    let totalRegistered: Int
    
    var isExpired: Bool {
        return Date() > expirationDate
    }
}

// MARK: - Manager para sesión temporal

class SessionCodeManager {
    static let shared = SessionCodeManager()
    
    private let sessionDataKey = "temporarySessionData"
    
    private init() {}
    
    // MARK: - Guardar sesión temporal
    func saveTemporarySession(_ response: SessionCodeResponse, code: String) {
        let expirationDate = Date().addingTimeInterval(6 * 60 * 60) // 6 horas
        let totalRegistered = response.registrantTypes.reduce(0) { $0 + ($1.registered ?? 0) }
        
        // Limpiar cache de checkins antes de guardar nueva sesión
        clearCheckinsCache()
        
        let sessionData = TemporarySessionData(
            sessionId: response.id,
            sessionName: response.name,
            sessionCode: code,
            eventId: response.event.id,
            eventName: response.event.name,
            expirationDate: expirationDate,
            startDate: response.startDate,
            endDate: response.endDate,
            startTime: response.startTime,
            endTime: response.endTime,
            registrantTypes: response.registrantTypes,
            totalRegistered: totalRegistered
        )
        
        if let encoded = try? JSONEncoder().encode(sessionData) {
            UserDefaults.standard.set(encoded, forKey: sessionDataKey)
            // Notificar que se validó una sesión
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .sessionCodeValidated, object: nil)
            }
        }
    }
    
    // MARK: - Obtener sesión temporal
    func getTemporarySession() -> TemporarySessionData? {
        guard let data = UserDefaults.standard.data(forKey: sessionDataKey),
              let sessionData = try? JSONDecoder().decode(TemporarySessionData.self, from: data) else {
            return nil
        }
        
        // Verificar si la sesión ha expirado
        if sessionData.isExpired {
            clearTemporarySession()
            return nil
        }
        
        return sessionData
    }
    
    // MARK: - Limpiar sesión temporal
    func clearTemporarySession() {
        UserDefaults.standard.removeObject(forKey: sessionDataKey)
        clearCheckinsCache()
    }
    
    // MARK: - Limpiar cache de checkins
    private func clearCheckinsCache() {
        // Remover todas las claves de cache de checkins (formato: "checkins_cache_eventId_sessionId")
        let defaults = UserDefaults.standard
        if let appDomain = Bundle.main.bundleIdentifier {
            let keysToRemove = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("checkins_cache_") }
            for key in keysToRemove {
                defaults.removeObject(forKey: key)
            }
        }
        print("💾 Cache de checkins limpiada")
    
    // MARK: - Validar código de sesión con la API
    @MainActor
    func validateSessionCode(_ code: String) async throws -> SessionCodeResponse {
        // Paso 1: Obtener token con credenciales de API
        let token = try await loginWithAPICredentials()
        
        // Paso 2: Validar el código de sesión
        guard let url = URL(string: "\(APIConstants.baseURL)event-sessions/\(code)") else {
            throw NSError(domain: "SessionCodeManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "SessionCodeManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Respuesta inválida del servidor"])
        }
        
        if http.statusCode == 404 {
            throw NSError(domain: "SessionCodeManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Código de sesión no encontrado"])
        }
        
        if http.statusCode != 200 {
            throw NSError(domain: "SessionCodeManager", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error del servidor"])
        }
        
        let sessionResponse = try JSONDecoder().decode(SessionCodeResponse.self, from: data)
        
        // Guardar la sesión temporal
        saveTemporarySession(sessionResponse, code: code)
        
        return sessionResponse
    }
    
    // MARK: - Login con credenciales de API
    func loginWithAPICredentials() async throws -> String {
        guard let url = URL(string: "\(APIConstants.baseURL)auth/login") else {
            throw NSError(domain: "SessionCodeManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": APIConstants.apiEmail,
            "password": APIConstants.apiPassword
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "SessionCodeManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al autenticar con la API"])
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        return authResponse.token
    }
}
