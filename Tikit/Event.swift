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
    let registrantType: RegistrantType?
    let price: Int
    let stock: Int?
    let used: Int?
    let available: Int?
    let isActive: Bool
    let registered: Int?
    let checkins: Int?
    let attendancePercentage: Double?
    
    enum CodingKeys: String, CodingKey {
        case id = "sessionRegistrantTypeId"
        case registrantTypeId
        case registrantTypeName
        case price
        case stock
        case used
        case available
        case isActive
        case registered
        case checkins
        case attendancePercentage
    }
    
    init(id: Int, registrantType: RegistrantType?, price: Int, stock: Int?, used: Int?, available: Int?, isActive: Bool, registered: Int?, checkins: Int?, attendancePercentage: Double?) {
        self.id = id
        self.registrantType = registrantType
        self.price = price
        self.stock = stock
        self.used = used
        self.available = available
        self.isActive = isActive
        self.registered = registered
        self.checkins = checkins
        self.attendancePercentage = attendancePercentage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        
        // Decodificar registrantType manualmente desde los campos planos
        if let typeId = try? container.decode(Int.self, forKey: .registrantTypeId),
           let typeName = try? container.decode(String.self, forKey: .registrantTypeName) {
            registrantType = RegistrantType(id: typeId, name: typeName, price: nil)
        } else {
            registrantType = nil
        }
        
        price = try container.decode(Int.self, forKey: .price)
        stock = try? container.decode(Int.self, forKey: .stock)
        used = try? container.decode(Int.self, forKey: .used)
        available = try? container.decode(Int.self, forKey: .available)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        registered = try? container.decode(Int.self, forKey: .registered)
        checkins = try? container.decode(Int.self, forKey: .checkins)
        attendancePercentage = try? container.decode(Double.self, forKey: .attendancePercentage)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(registrantType?.id, forKey: .registrantTypeId)
        try container.encodeIfPresent(registrantType?.name, forKey: .registrantTypeName)
        try container.encode(price, forKey: .price)
        try container.encodeIfPresent(stock, forKey: .stock)
        try container.encodeIfPresent(used, forKey: .used)
        try container.encodeIfPresent(available, forKey: .available)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(registered, forKey: .registered)
        try container.encodeIfPresent(checkins, forKey: .checkins)
        try container.encodeIfPresent(attendancePercentage, forKey: .attendancePercentage)
    }
}

struct RegistrantType: Codable, Identifiable {
    let id: Int
    let name: String
    let price: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case registrantTypeId
        case name
        case registrantTypeName
        case price
        case createdAt
        case updatedAt
        case isDefault
        case isVisible
        case stock
    }
    
    init(id: Int, name: String, price: Int?) {
        self.id = id
        self.name = name
        self.price = price
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Intentar decodificar id desde "id" o "registrantTypeId"
        if let idValue = try? container.decode(Int.self, forKey: .id) {
            id = idValue
        } else if let idValue = try? container.decode(Int.self, forKey: .registrantTypeId) {
            id = idValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.id, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No id or registrantTypeId found"))
        }
        
        // Intentar decodificar name desde "name" o "registrantTypeName"
        if let nameValue = try? container.decode(String.self, forKey: .name) {
            name = nameValue
        } else if let nameValue = try? container.decode(String.self, forKey: .registrantTypeName) {
            name = nameValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.name, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No name or registrantTypeName found"))
        }
        
        price = try? container.decode(Int.self, forKey: .price)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(price, forKey: .price)
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
    let eventId: Int
    let eventName: String
    let sessions: [EventSession]
    let totalSessions: Int
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
