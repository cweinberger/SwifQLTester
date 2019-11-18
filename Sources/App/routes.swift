import Fluent
import FluentMySQL
import SwifQL
import SwifQLVapor
import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }

    router.get("debug/add-testdata") { req -> EventLoopFuture<Response> in
        return req.withNewConnection(to: .mysql) { connection in
            let todos = [
                Todo(title: "first todo"),
                Todo(title: "second todo"),
                Todo(title: "third todo")
            ]

            return todos.map { $0.save(on: connection) }
                .flatten(on: req)
                .transform(to: Response(http: HTTPResponse(status: .created), using: req))
        }
    }

    // WORKS!
    router.get("swifql/get-todos-1") { req -> EventLoopFuture<[Todo]> in
        return req.withNewConnection(to: .mysql) { connection -> EventLoopFuture<[Todo]> in

            let query = SwifQL
                .select(Todo.table.*)
                .from(Todo.table)

            return query
                .execute(on: connection)
                .all(decoding: Todo.self)
        }
    }

    // DOESN'T WORK
    router.get("swifql/get-todos-2") { req -> EventLoopFuture<[Todo]> in
        return req.withNewConnection(to: .mysql) { connection -> EventLoopFuture<[Todo]> in

            let todo = Todo.as("t")

            let query = SwifQL
                .select(todo.*)
                .from(todo.table)

            /* Produces fine SQL query:

            SELECT t.*
            FROM Todo AS t

            */

            return query
                .execute(on: connection)
                .all(decoding: Todo.self)
            /*

             This calls `public func all<A>(decoding type: A.Type) -> Future<[A]> where A: Decodable` from
             (in SQL > SQLQueryFetcher.swift)
             Where the entity name (`t`) is not taken into account!

             UNLIKE Fluent, which has

             `public func alsoDecode<D>(_ type: D.Type, _ entity: String) -> QueryBuilder<Database, (Result, D)> where D: Decodable`
             (in Fluent > QueryBuilder+Decode.swift)

             */
        }
    }

    // DOESN'T WORK
    router.get("swifql/get-todos-3") { req -> EventLoopFuture<[Todo]> in
        return req.withNewConnection(to: .mysql) { connection -> EventLoopFuture<[Todo]> in

            let todo1 = Todo.as("t1")
            let todo2 = Todo.as("t2")

            let query = SwifQL
                .select(todo1.*, todo2.*)
                .from(todo1.table)
                .join(.left, todo2.table, on: todo1~\.id == todo2~\.id)

            /* Produces fine SQL query:

             SELECT t1.* , t2.*
             FROM Todo AS t1
             LEFT JOIN Todo AS t2
                ON t1.id = t2.id

             */

            return query
                .execute(on: connection)
                .all(decoding: Todo.self, Todo.self)
                .map { todos in
                    // return only first todo to make it build
                    return todos.map { $0.0 }
                }
        }
    }
}
