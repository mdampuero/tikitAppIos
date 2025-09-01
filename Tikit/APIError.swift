import Foundation

/// Generic API error response that can contain both field-specific validation errors and a general message.
struct APIErrorResponse: Codable {
    let message: String?
    let errors: [String: [String]]?
}

extension APIErrorResponse {
    /// Convenience computed property that maps each field to its first error message.
    var fieldErrors: [String: String] {
        errors?.mapValues { $0.first ?? "" } ?? [:]
    }
}
