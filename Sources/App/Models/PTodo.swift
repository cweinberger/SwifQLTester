import FluentPostgreSQL
import Vapor

final class PTodo: Codable {
    var id: Int?
    var title: String

    init(id: Int? = nil, title: String) {
        self.id = id
        self.title = title
    }
}

extension PTodo: PostgreSQLModel { }

/// Allows `Todo` to be used as a dynamic migration.
extension PTodo: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension PTodo: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension PTodo: Parameter { }
