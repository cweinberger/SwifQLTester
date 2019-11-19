import SQL

extension SQLQueryFetcher {

    public func all<A>(
        decoding type: A.Type, entity: String
    ) -> Future<[A]>
        where A: Decodable
    {
        var all: [A] = []
        return run(decoding: A.self, entity: entity) { all.append($0) }.map { all }
    }

    public func all<A, B>(
        decoding a: A.Type, entity entityA: String,
        _ b: B.Type, entity entityB: String
    ) -> Future<[(A, B)]>
        where A: Decodable, B: Decodable
    {
        var all: [(A, B)] = []
        return run(decoding: A.self, entity: entityA, B.self, entity: entityB) { all.append(($0, $1)) }.map { all }
    }

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
