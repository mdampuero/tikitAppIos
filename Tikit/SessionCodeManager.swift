import Foundation

// MARK: - Modelos de respuesta de la API

struct SessionCodeResponse: Codable {
    let id: Int
    let name: String
    let description: String?
    let code: String
    let startDate: String
    let endDate: String
    let startTime: String
    let endTime: String
    let isDefault: Bool
    let createdAt: String
    let updatedAt: String?
    let event: SessionEvent
    let registrantTypes: [SessionRegistrantType]
    
    // Hacer el decoder flexible para ignorar campos extras
    enum CodingKeys: String, CodingKey {
        case id, name, description, code, startDate, endDate, startTime, endTime, isDefault, createdAt, updatedAt, event, registrantTypes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        code = try container.decode(String.self, forKey: .code)
        startDate = try container.decode(String.self, forKey: .startDate)
        endDate = try container.decode(String.self, forKey: .endDate)
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        event = try container.decode(SessionEvent.self, forKey: .event)
        registrantTypes = try container.decodeIfPresent([SessionRegistrantType].self, forKey: .registrantTypes) ?? []
    }
}

struct SessionEvent: Codable {
    let id: Int
    let name: String
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decodeIfPresent(String.self, forKey: .type)
    }
}

// MARK: - Datos de sesión temporal guardados

struct TemporarySessionData: Codable {
    let sessionId: Int
    let sessionName: String
    let sessionCode: String
    let eventId: Int
    let eventName: String
    let sessionStartTime: Date  // Hora de inicio de la sesión
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
    
    var timeRemaining: TimeInterval {
        return max(0, expirationDate.timeIntervalSince(Date()))
    }
    
    enum CodingKeys: String, CodingKey {
        case sessionId, sessionName, sessionCode, eventId, eventName, sessionStartTime, expirationDate, startDate, endDate, startTime, endTime, registrantTypes, totalRegistered
    }
    
    init(sessionId: Int, sessionName: String, sessionCode: String, eventId: Int, eventName: String, sessionStartTime: Date, expirationDate: Date, startDate: String, endDate: String, startTime: String, endTime: String, registrantTypes: [SessionRegistrantType], totalRegistered: Int) {
        self.sessionId = sessionId
        self.sessionName = sessionName
        self.sessionCode = sessionCode
        self.eventId = eventId
        self.eventName = eventName
        self.sessionStartTime = sessionStartTime
        self.expirationDate = expirationDate
        self.startDate = startDate
        self.endDate = endDate
        self.startTime = startTime
        self.endTime = endTime
        self.registrantTypes = registrantTypes
        self.totalRegistered = totalRegistered
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(Int.self, forKey: .sessionId)
        sessionName = try container.decode(String.self, forKey: .sessionName)
        sessionCode = try container.decode(String.self, forKey: .sessionCode)
        eventId = try container.decode(Int.self, forKey: .eventId)
        eventName = try container.decode(String.self, forKey: .eventName)
        sessionStartTime = try container.decode(Date.self, forKey: .sessionStartTime)
        expirationDate = try container.decode(Date.self, forKey: .expirationDate)
        startDate = try container.decode(String.self, forKey: .startDate)
        endDate = try container.decode(String.self, forKey: .endDate)
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)
        registrantTypes = try container.decodeIfPresent([SessionRegistrantType].self, forKey: .registrantTypes) ?? []
        totalRegistered = try container.decodeIfPresent(Int.self, forKey: .totalRegistered) ?? 0
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
            sessionStartTime: Date(),
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
    
    // MARK: - Actualizar sesión temporal silenciosamente (sin notificaciones)
    func updateTemporarySessionSilently(_ response: SessionCodeResponse) {
        let totalRegistered = response.registrantTypes.reduce(0) { $0 + ($1.registered ?? 0) }
        
        guard let currentSession = getTemporarySession() else { return }
        
        let sessionData = TemporarySessionData(
            sessionId: response.id,
            sessionName: response.name,
            sessionCode: currentSession.sessionCode,
            eventId: response.event.id,
            eventName: response.event.name,
            sessionStartTime: currentSession.sessionStartTime,
            expirationDate: currentSession.expirationDate,
            startDate: response.startDate,
            endDate: response.endDate,
            startTime: response.startTime,
            endTime: response.endTime,
            registrantTypes: response.registrantTypes,
            totalRegistered: totalRegistered
        )
        
        if let encoded = try? JSONEncoder().encode(sessionData) {
            UserDefaults.standard.set(encoded, forKey: sessionDataKey)
            // NO disparar notificación - solo actualizar datos silenciosamente
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
    }
    
    // MARK: - Validar código de sesión con la API
    @MainActor
    func validateSessionCode(_ code: String) async throws -> SessionCodeResponse {
            print("🔍 [SessionCodeManager] Iniciando validación de código: \(code)")
            
            // Paso 1: Obtener token con credenciales de API
            print("🔐 [SessionCodeManager] Obteniendo token de API...")
            let token = try await loginWithAPICredentials()
            print("✅ [SessionCodeManager] Token obtenido correctamente")
            
            // Paso 2: Validar el código de sesión
            let urlString = "\(APIConstants.baseURL)event-sessions/\(code)"
            print("🌐 [SessionCodeManager] URL: \(urlString)")
            
            guard let url = URL(string: urlString) else {
                throw NSError(domain: "SessionCodeManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            print("📤 [SessionCodeManager] Enviando request GET...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse else {
                print("❌ [SessionCodeManager] Respuesta no es HTTPURLResponse")
                throw NSError(domain: "SessionCodeManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Respuesta inválida del servidor"])
            }
            
            print("📥 [SessionCodeManager] Status Code: \(http.statusCode)")
            
            // DEBUG: Imprimir respuesta completa
            if let responseString = String(data: data, encoding: .utf8) {
                print("📋 [SessionCodeManager] Respuesta JSON completa:")
                print("---START JSON---")
                print(responseString)
                print("---END JSON---")
            } else {
                print("❌ [SessionCodeManager] No se pudo decodificar la respuesta como string")
            }
            
            if http.statusCode == 404 {
                print("❌ [SessionCodeManager] Código no encontrado (404)")
                throw NSError(domain: "SessionCodeManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Código de sesión no encontrado"])
            }
            
            if http.statusCode != 200 {
                print("❌ [SessionCodeManager] Status code no es 200: \(http.statusCode)")
                throw NSError(domain: "SessionCodeManager", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error del servidor"])
            }
            
            print("🔄 [SessionCodeManager] Intentando decodificar JSON...")
            let sessionResponse = try JSONDecoder().decode(SessionCodeResponse.self, from: data)
            
            print("✅ [SessionCodeManager] Decodificación exitosa")
            // Guardar la sesión temporal
            saveTemporarySession(sessionResponse, code: code)
            
            return sessionResponse
        }
        
    // MARK: - Login con credenciales de API
    func loginWithAPICredentials() async throws -> String {
            print("🔐 [SessionCodeManager] Iniciando login con credenciales de API...")
            
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
            
            print("📤 [SessionCodeManager] Enviando login request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                print("❌ [SessionCodeManager] Login fallido con status: \(statusCode)")
                if let errorStr = String(data: data, encoding: .utf8) {
                    print("   Error response: \(errorStr)")
                }
                throw NSError(domain: "SessionCodeManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al autenticar con la API"])
            }
            
            print("✅ [SessionCodeManager] Login exitoso, decodificando token...")
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            print("✅ [SessionCodeManager] Token obtenido: \(authResponse.token.prefix(20))...")
            return authResponse.token
        }
    
    // MARK: - Actualizar datos de sesión silenciosamente
    @MainActor
    func refreshSessionDataSilently() async -> TemporarySessionData? {
        do {
            guard let currentSession = getTemporarySession() else {
                print("❌ [SessionCodeManager] No hay sesión temporal activa")
                return nil
            }
            
            print("🔄 [SessionCodeManager] Actualizando datos de sesión: \(currentSession.sessionCode)")
            
            // Obtener token
            let token = try await loginWithAPICredentials()
            
            // Llamar a la API
            let urlString = "\(APIConstants.baseURL)event-sessions/\(currentSession.sessionCode)"
            guard let url = URL(string: urlString) else {
                print("❌ [SessionCodeManager] URL inválida")
                return nil
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("❌ [SessionCodeManager] Error al actualizar sesión: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return nil
            }
            
            // Decodificar respuesta
            let sessionResponse = try JSONDecoder().decode(SessionCodeResponse.self, from: data)
            
            // Actualizar datos locales sin disparar notificaciones
            updateTemporarySessionSilently(sessionResponse)
            
            print("✅ [SessionCodeManager] Datos de sesión actualizados correctamente")
            return getTemporarySession()
            
        } catch {
            print("❌ [SessionCodeManager] Error al actualizar sesión: \(error.localizedDescription)")
            return nil
        }
    }
}

