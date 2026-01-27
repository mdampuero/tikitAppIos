import Foundation

struct Translations {
    static let errorMessages: [String: String] = [
        "Guest has already checked in for this session": "Esta persona ya realizó check-in en esta sesión.",
        "Registrant or session not found": "Solicitud inválida. El registrante o la sesión no existen.",
        "Guest not found for this session": "No se encontró a esta persona en la sesión."
        // Agrega más traducciones aquí
    ]

    static func translate(_ message: String) -> String {
        return errorMessages[message] ?? message
    }
}
