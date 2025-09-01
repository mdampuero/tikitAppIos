import Foundation

struct Event: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let accessType: String
    let isActive: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case accessType
        case isActive
        case createdAt
    }

    var createdDateFormatted: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: createdAt) else { return createdAt }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }
}

struct EventsResponse: Codable {
    let data: [Event]
    let pagination: Pagination
}

struct Pagination: Codable {
    let currentPage: Int
    let perPage: Int
    let totalItems: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case perPage = "per_page"
        case totalItems = "total_items"
        case totalPages = "total_pages"
    }
}

struct SessionsResponse: Codable {
    let sessions: [EventSession]
}

struct EventSession: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let createdAt: String?
    let updatedAt: String?
    let isDefault: Bool?
    let startDate: String?
    let startTime: String?
    let endDate: String?
    let endTime: String?

    var dateRangeFormatted: String? {
        let startComponents = [startDate, startTime].compactMap { $0 }.joined(separator: " ")
        let endComponents = [endDate, endTime].compactMap { $0 }.joined(separator: " ")
        if !startComponents.isEmpty && !endComponents.isEmpty {
            return "\(startComponents) - \(endComponents)"
        } else if !startComponents.isEmpty {
            return startComponents
        } else if !endComponents.isEmpty {
            return endComponents
        }
        return nil
    }
}
