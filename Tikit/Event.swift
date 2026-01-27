import Foundation

struct Event: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let accessType: String
    let isActive: Bool
    let createdAt: String
    let startDate: String?
    let endDate: String?
    let place: String?
    let address: String?
    let addressCity: String?
    let categories: [Category]?
    let landingMedia: [LandingMedia]?
    let registrantsCount: Int?
    let description: String?
    let slug: String?

    enum CodingKeys: String, CodingKey {
        case id, name, accessType, isActive, createdAt, startDate, endDate, place, address, addressCity, categories, landingMedia, registrantsCount, description, slug
    }

    var createdDateFormatted: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: createdAt) else { return createdAt }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }
    
    var eventDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        
        if let startDate = startDate {
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: startDate) {
                let formatted = formatter.string(from: date)
                return formatted
            }
        }
        return ""
    }
    
    var coverImageURL: URL? {
        if let landingMedia = landingMedia, let first = landingMedia.first {
            let path = first.path.hasPrefix("http") ? first.path : "https://tikit.cl\(first.path)"
            return URL(string: path)
        }
        return URL(string: "https://tikit.cl/static/tikit/default.jpg")
    }
}

struct Category: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
}

struct LandingMedia: Codable, Identifiable, Equatable {
    let id: Int
    let path: String
    let isDefault: Bool?
}

struct SessionRegistrantType: Codable, Identifiable {
    let id: Int
    let registrantType: RegistrantType
    let price: Int
    let stock: Int
    let used: Int
    let available: Int
    let isActive: Bool
}

struct RegistrantType: Codable, Identifiable {
    let id: Int
    let name: String
    let price: Int
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
    let registrantTypes: [SessionRegistrantType]?

    var dateRangeFormatted: String? {
        let inputFormatter = ISO8601DateFormatter()
        let altFormatter = DateFormatter()
        altFormatter.dateFormat = "yyyy-MM-dd"
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd/MM/yyyy"

        func formattedDate(from string: String?) -> String? {
            guard let string = string else { return nil }
            if let date = inputFormatter.date(from: string) {
                return displayFormatter.string(from: date)
            }
            if let date = altFormatter.date(from: string) {
                return displayFormatter.string(from: date)
            }
            return nil
        }

        let start = formattedDate(from: startDate)
        let end = formattedDate(from: endDate)
        if let start = start, let end = end {
            return "\(start) - \(end)"
        } else if let start = start {
            return start
        } else if let end = end {
            return end
        }
        return nil
    }
}
