import Foundation

struct CheckinResponse: Codable {
    struct Guest: Codable {
        let id: Int
        let firstName: String
        let lastName: String
        let email: String
        let registrantType: RegistrantType?

        var fullName: String {
            "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        }
    }

    struct EventSessionInfo: Codable, Identifiable {
        let id: Int
        let name: String
    }

    let id: Int
    let guest: Guest
    let eventSession: EventSessionInfo
    let method: String
    let latitude: Double?
    let longitude: Double?
    let createdAt: String?
    let updatedAt: String?
}

struct CheckinAPIErrorResponse: Codable {
    let message: String?
    let error: String?
}

struct CheckinData: Codable, Identifiable {
    let id: Int
    let guest: CheckinResponse.Guest
    let eventSession: CheckinResponse.EventSessionInfo
    let method: String
    let latitude: Double?
    let longitude: Double?
    let createdAt: String?
    let updatedAt: String?
}

struct CheckinsResponse: Codable {
    let data: [CheckinData]
    let pagination: CheckinPagination
}

struct CheckinPagination: Codable {
    let current_page: Int
    let per_page: Int
    let total_items: Int
    let total_pages: Int
}
