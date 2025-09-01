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

struct EventDetailResponse: Codable {
    let data: EventDetail
}

struct EventDetail: Codable {
    let id: Int
    let name: String
    let sessions: [EventSession]
}

struct EventSession: Codable, Identifiable {
    let id: Int
    let startsAt: String
    let endsAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case startsAt = "starts_at"
        case endsAt = "ends_at"
    }

    var startDateFormatted: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: startsAt) else { return startsAt }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }

    var endDateFormatted: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: endsAt) else { return endsAt }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }
}
