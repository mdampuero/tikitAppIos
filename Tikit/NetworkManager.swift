import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private var sessionManager: SessionManager?
    
    func setSessionManager(_ sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }
    
    /// Realiza una request con manejo automático de refresh token en caso de 401
    func dataRequest(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await performRequest(request, retryCount: 0)
    }
    
    private func performRequest(_ request: URLRequest, retryCount: Int) async throws -> (Data, URLResponse) {
        var mutableRequest = request
        
        // Asegurar que siempre incluya el JWT actual si está disponible
        if let token = sessionManager?.token {
            mutableRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: mutableRequest)
        
        // Si recibimos 401 y aún tenemos reintentos disponibles
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401, retryCount < 1 {
            // Intentar refrescar el token
            if await sessionManager?.refreshAuthToken() ?? false {
                // Si el refresh fue exitoso, reintentar la request original
                return try await performRequest(request, retryCount: retryCount + 1)
            } else {
                // Si el refresh falló, hacer logout
                await sessionManager?.logout()
                throw NetworkError.unauthorized
            }
        }
        
        return (data, response)
    }
}

enum NetworkError: LocalizedError {
    case unauthorized
    case invalidURL
    case decodingError
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "No autorizado. Por favor, inicia sesión nuevamente."
        case .invalidURL:
            return "URL inválida"
        case .decodingError:
            return "Error al procesar la respuesta del servidor"
        case .serverError(let code):
            return "Error del servidor (\(code))"
        }
    }
}
