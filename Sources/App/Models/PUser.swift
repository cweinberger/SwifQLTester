import FluentPostgreSQL
import Vapor

final class PUser: Codable {
    var id: Int?
    var name: String

    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension PUser: PostgreSQLModel { }

/// Allows `Todo` to be used as a dynamic migration.
extension PUser: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension PUser: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension PUser: Parameter { }
