import SQL

extension SQLQueryFetcher {

    /// Collects all decoded output into an array and returns it.
    ///
    ///     builder.all(decoding: Planet.self, entity: "pl")
    ///
    public func all<A>(
        decoding type: A.Type, entity: String
    ) -> Future<[A]>
        where A: Decodable
    {
        var all: [A] = []
        return run(decoding: A.self, entity: entity) { all.append($0) }.map { all }
    }

    /// Decodes two types from the result set. Collects all decoded output into an array and returns it.
    ///
    ///     builder.all(decoding: Planet.self, entity: "pl", Galaxy.self, entity: "gal")
    ///
    public func all<A, B>(
        decoding a: A.Type, entity entityA: String,
        _ b: B.Type, entity entityB: String
    ) -> Future<[(A, B)]>
        where A: Decodable, B: Decodable
    {
        var all: [(A, B)] = []
        return run(decoding: A.self, entity: entityA, B.self, entity: entityB) { all.append(($0, $1)) }.map { all }
    }

    /// Decodes three types from the result set. Collects all decoded output into an array and returns it.
    ///
    ///     builder.all(decoding: Planet.self, entity: "pl", Galaxy.self, entity: "gal", SolarSystem.self, entity: "solar")
    ///
    public func all<A, B, C>(
        decoding a: A.Type, entity entityA: String,
        _ b: B.Type, entity entityB: String,
        _ c: C.Type, entity entityC: String
    ) -> Future<[(A, B, C)]>
        where A: Decodable, B: Decodable, C: Decodable
    {
        var all: [(A, B, C)] = []
        return run(decoding: A.self, entity: entityA, B.self, entity: entityB, C.self, entity: entityC) { all.append(($0, $1, $2)) }.map { all }
    }

    /// Decodes four types from the result set. Collects all decoded output into an array and returns it.
    ///
    ///     builder.all(decoding: Planet.self, entity: "pl1", Planet.self, entity: "pl2", Galaxy.self, entity: "gal", SolarSystem.self, entity: "solar")
    ///
    public func all<A, B, C, D>(
        decoding a: A.Type, entity entityA: String,
        _ b: B.Type, entity entityB: String,
        _ c: C.Type, entity entityC: String,
        _ d: D.Type, entity entityD: String
    ) -> Future<[(A, B, C, D)]>
        where A: Decodable, B: Decodable, C: Decodable, D: Decodable
    {
        var all: [(A, B, C, D)] = []
        return run(
            decoding: A.self, entity: entityA,
            B.self, entity: entityB,
            C.self, entity: entityC,
            D.self, entity: entityD
        ) { all.append(($0, $1, $2, $3)) }.map { all }
    }

    /// Runs the query, passing decoded output to the supplied closure as it is recieved.
    ///
    ///     builder.run(decoding: Planet.self, entity: "pl") { planet in
    ///         // ..
    ///     }
    ///
    /// The returned future will signal completion of the query.
    public func run<A>(
        decoding type: A.Type,
        entity: String,
        into handler: @escaping (A) throws -> ()
    ) -> Future<Void>
        where A: Decodable
    {
        return connectable.withSQLConnection { conn in
            return conn.query(self.query) { row in
                let d = try conn.decode(A.self, from: row, table: Self.Connectable.Connection.Query.Select.TableIdentifier.table(.identifier(entity)))
                try handler(d)
            }
        }
    }

    /// Runs the query, passing decoded output to the supplied closure as it is recieved.
    ///
    ///     builder.run(decoding: Planet.self, entity: "pl", Galaxy.self, entity: "gal") { planet, galaxy in
    ///         // ..
    ///     }
    ///
    /// The returned future will signal completion of the query.
    public func run<A, B>(
        decoding a: A.Type, entity entityA: String,
        _ b: B.Type, entity entityB: String,
        into handler: @escaping (A, B) throws -> ()
    ) -> Future<Void>
        where A: Decodable, B: Decodable
    {
        return connectable.withSQLConnection { conn in
            return conn.query(self.query) { row in
                let a = try conn.decode(A.self, from: row, table: Self.Connectable.Connection.Query.Select.TableIdentifier.table(.identifier(entityA)))
                let b = try conn.decode(B.self, from: row, table: Self.Connectable.Connection.Query.Select.TableIdentifier.table(.identifier(entityB)))
                try handler(a, b)
            }
        }
    }

    /// Runs the query, passing decoded output to the supplied closure as it is recieved.
    ///
    ///     builder.run(decoding: Planet.self, entity: "pl", Galaxy.self, entity: "gal", SolarSystem.self, entity: "solar") { planet, galaxy, solarSystem in
    ///         // ..
    ///     }
    ///
    /// The returned future will signal completion of the query.
    public func run<A, B, C>(
        decoding a: A.Type, entity entityA: String,
        _ b: B.Type, entity entityB: String,
        _ c: C.Type, entity entityC: String,
        into handler: @escaping (A, B, C) throws -> ()
    ) -> Future<Void>
        where A: Decodable, B: Decodable, C: Decodable
    {
        return connectable.withSQLConnection { conn in
            return conn.query(self.query) { row in
                let a = try conn.decode(A.self, from: row, table: Self.Connectable.Connection.Query.Select.TableIdentifier.table(.identifier(entityA)))
                let b = try conn.decode(B.self, from: row, table: Self.Connectable.Connection.Query.Select.TableIdentifier.table(.identifier(entityB)))
                let c = try conn.decode(C.self, from: row, table: Self.Connectable.Connection.Query.Select.TableIdentifier.table(.identifier(entityC)))
                try handler(a, b, c)
            }
        }
    }

    /// Runs the query, passing decoded output to the supplied closure as it is recieved.
    ///
    ///     builder.run(decoding: Planet.self, entity: "pl1", Planet.self, entity: "pl2", Galaxy.self, entity: "gal", SolarSystem.self, entity: "solar") { planet1, planet2, galaxy, solarSystem in
    ///         // ..
    ///     }
    ///
    /// The returned future will signal completion of the query.
    public func run<A, B, C, D>(
        decoding a: A.Type, entity entityA: String,
        _ b: B.Type, entity entityB: String,
        _ c: C.Type, entity entityC: String,
        _ d: D.Type, entity entityD: String,
        into handler: @escaping (A, B, C, D) throws -> ()
    ) -> Future<Void>
        where A: Decodable, B: Decodable, C: Decodable, D: Decodable
    {
        return connectable.withSQLConnection { conn in
            return conn.query(self.query) { row in
                let a = try conn.decode(A.self, from: row, table: Self.Connectable.Connection.Query.Select.TableIdentifier.table(.identifier(entityA)))
                let b = try conn.decode(B.self, from: row, table: Self.Connectable.Connection.Query.Select.TableIdentifier.table(.identifier(entityB)))
                let c = try conn.decode(C.self, from: row, table: Self.Connectable.Connection.Query.Select.TableIdentifier.table(.identifier(entityC)))
                let d = try conn.decode(D.self, from: row, table: Self.Connectable.Connection.Query.Select.TableIdentifier.table(.identifier(entityD)))
                try handler(a, b, c, d)
            }
        }
    }
}
