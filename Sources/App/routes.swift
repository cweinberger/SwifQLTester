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
                Todo(id: 1, title: "first todo"),
                Todo(id: 2, title: "second todo"),
                Todo(id: 3, title: "third todo")
            ]

            let user = [
                User(id: 500, name: "User 500"),
                User(id: 600, name: "User 600"),
                User(id: 700, name: "User 700")
            ]

            return todos.map { $0.create(orUpdate: true, on: connection) }
                .flatten(on: req)
                .flatMap { _ in
                    user.map { $0.create(orUpdate: true, on: connection) }
                        .flatten(on: req)
                }
                .transform(to: Response(http: HTTPResponse(status: .created), using: req))
        }
    }

    router.get("debug/psql/add-testdata") { req -> EventLoopFuture<Response> in
        return req.withNewConnection(to: .psql) { connection in
            let todos = [
                PTodo(id: 1, title: "first todo"),
                PTodo(id: 2, title: "second todo"),
                PTodo(id: 3, title: "third todo")
            ]

            let user = [
                PUser(id: 500, name: "User 500"),
                PUser(id: 600, name: "User 600"),
                PUser(id: 700, name: "User 700")
            ]

            return todos.map { $0.create(orUpdate: true, on: connection) }
                .flatten(on: req)
                .flatMap { _ in
                    user.map { $0.create(orUpdate: true, on: connection) }
                        .flatten(on: req)
                }
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

    // DOESN'T WORK; FIXED by https://github.com/vapor/mysql-kit/pull/244
    router.get("swifql/get-todos-2") { req -> EventLoopFuture<[Todo]> in
        return req.withNewConnection(to: .mysql) { connection -> EventLoopFuture<[Todo]> in

            let todo = Todo.as("t1")

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

    // DOESN'T WORK; FIXED by https://github.com/vapor/mysql-kit/pull/244
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

    // DOESN'T WORK
    router.get("swifql/get-todos-4") { req -> EventLoopFuture<[TodosResponse]> in
        return req.withNewConnection(to: .mysql) { connection -> EventLoopFuture<[TodosResponse]> in

            let todo1 = Todo.as("t1")
            let todo2 = Todo.as("t2")

            let query = SwifQL
                .select(todo1.*, todo2.*)
                .from(todo1.table)
                .join(.left, todo2.table, on: todo1~\.id != todo2~\.id)

            /* Produces fine SQL query:

             SELECT t1.* , t2.*
             FROM Todo AS t1
             LEFT JOIN Todo AS t2
                ON t1.id != t2.id

             */

            return query
                .execute(on: connection)
                .all(decoding: Todo.self, Todo.self)
                .map { result in
                    return result.map { (todo1, todo2) in TodosResponse(todo1: todo1, todo2: todo2) }
                }
        }
    }

    // DOESN'T WORK
    router.get("swifql/get-todos-5") { req -> EventLoopFuture<[TodoUserResponse]> in
        return req.withNewConnection(to: .mysql) { connection -> EventLoopFuture<[TodoUserResponse]> in

            let todo = Todo.as("t")
            let user = User.as("u")

            let query = SwifQL
                .select(todo.*, user.*)
                .from(todo.table)
                .join(.left, user.table, on: todo~\.id != user~\.id)

            /* Produces fine SQL query:

             SELECT t.* , u.*
             FROM Todo AS t
             LEFT JOIN User AS u
                ON t.id != u.id

             */

            return query
                .execute(on: connection)
                .all(decoding: Todo.self, User.self)
                .map { result in
                    return result.map { (todo, user) in TodoUserResponse(todo: todo, user: user) }
                }
        }
    }

    // FIXED using `SQLQueryFetcher+Aliases.swift´
    router.get("swifql/fixed/get-todos-2") { req -> EventLoopFuture<[Todo]> in
        return req.withNewConnection(to: .mysql) { connection -> EventLoopFuture<[Todo]> in

            let todo = Todo.as("t1")

            let query = SwifQL
                .select(todo.*)
                .from(todo.table)

            return query
                .execute(on: connection)
                .all(decoding: Todo.self, entity: "t1")
        }
    }

    // FIXED using `SQLQueryFetcher+Aliases.swift´
    router.get("swifql/fixed/get-todos-3") { req -> EventLoopFuture<[Todo]> in
        return req.withNewConnection(to: .mysql) { connection -> EventLoopFuture<[Todo]> in

            let todo1 = Todo.as("t1")
            let todo2 = Todo.as("t2")

            let query = SwifQL
                .select(todo1.*, todo2.*)
                .from(todo1.table)
                .join(.left, todo2.table, on: todo1~\.id == todo2~\.id)

            return query
                .execute(on: connection)
                .all(decoding: Todo.self, entity: "t1", Todo.self, entity: "t2")
                .map { todos in
                    return todos.map { $0.0 }
                }
        }
    }

    // FIXED using `SQLQueryFetcher+Aliases.swift´
    router.get("swifql/fixed/get-todos-4") { req -> EventLoopFuture<[TodosResponse]> in
        return req.withNewConnection(to: .mysql) { connection -> EventLoopFuture<[TodosResponse]> in

            let todo1 = Todo.as("t1")
            let todo2 = Todo.as("t2")

            let query = SwifQL
                .select(todo1.*, todo2.*)
                .from(todo1.table)
                .join(.left, todo2.table, on: todo1~\.id != todo2~\.id)

            return query
                .execute(on: connection)
                .all(decoding: Todo.self, entity: "t1", Todo.self, entity: "t2")
                .map { result in
                    return result.map { (todo1, todo2) in TodosResponse(todo1: todo1, todo2: todo2) }
                }
        }
    }

    // FIXED using `SQLQueryFetcher+Aliases.swift´
    router.get("swifql/fixed/get-todos-5") { req -> EventLoopFuture<[TodoUserResponse]> in
        return req.withNewConnection(to: .mysql) { connection -> EventLoopFuture<[TodoUserResponse]> in

            let todo = Todo.as("t")
            let user = User.as("u")

            let query = SwifQL
                .select(todo.*, user.*)
                .from(todo.table)
                .join(.left, user.table, on: todo~\.id != user~\.id)

            return query
                .execute(on: connection)
                .all(decoding: Todo.self, entity: "t", User.self, entity: "u")
                .map { result in
                    return result.map { (todo, user) in TodoUserResponse(todo: todo, user: user) }
                }
        }
    }

    // FIXED using `SQLQueryFetcher+Aliases.swift´
    router.get("swifql/fixed/get-todos-6") { req -> EventLoopFuture<[TodoTodoUserResponse]> in
        return req.withNewConnection(to: .mysql) { connection -> EventLoopFuture<[TodoTodoUserResponse]> in

            let todo1 = Todo.as("t1")
            let todo2 = Todo.as("t2")
            let user = User.as("u")

            let query = SwifQL
                .select(user.*, todo1.*, todo2.*)
                .from(user.table)
                .join(.left, todo1.table, on: todo1~\.id == 1)
                .join(.left, todo2.table, on: todo2~\.id == 2)

            return query
                .execute(on: connection)
                .all(
                    decoding: User.self, entity: "u",
                    Todo.self, entity: "t1",
                    Todo.self, entity: "t2")
                .map { result in
                    return result.map { (user, todo1, todo2) in TodoTodoUserResponse(todo1: todo1, todo2: todo2, user: user) }
                }
        }
    }

    // ISSUE WITH MYSQL ROWS (using subquery)
    router.get("swifql/fixed/get-todos-7") { req -> EventLoopFuture<[TodoUserResponse]> in
        return req.withNewConnection(to: .mysql) { connection -> EventLoopFuture<[TodoUserResponse]> in

            let todo1 = Todo.as("t1")
            let joinedTodo1 = Todo.as("joinedTodo1")
            let user = User.as("u")

            let query = SwifQL
                .select(user.*, todo1.*)
                .from(user.table)
                .join(.left, todo1.table, on: todo1~\.id == |(
                    SwifQL
                        .select(joinedTodo1~\.id)
                        .from(joinedTodo1.table)
                        .where(joinedTodo1~\.id == 1)
                        .orderBy(.desc(joinedTodo1~\.title))
                        .limit("0,1")
                    )|
                )

            return query
                .execute(on: connection)
                .all(decoding: User.self, Todo.self)
                .map { result in
                    return result.map { (user, todo) in TodoUserResponse(todo: todo, user: user) }
            }
        }
    }

    // ISSUE WITH MYSQL ROWS (using subquery, no aliases)
    router.get("swifql/fixed/get-todos-8") { req -> EventLoopFuture<[TodoUserResponse]> in
        return req.withNewConnection(to: .mysql) { connection -> EventLoopFuture<[TodoUserResponse]> in

            let query = SwifQL
                .select(User.table.*, Todo.table.*)
                .from(User.table)
                .join(.left, Todo.table, on: \Todo.id == |(
                    SwifQL
                        .select(\Todo.id)
                        .from(Todo.table)
                        .where(\Todo.id == 1)
                        .orderBy(.desc(\Todo.title))
                        .limit("0,1")
                    )|
                )

            /* Produces

             SELECT User.* , Todo.* FROM User LEFT JOIN Todo ON Todo.id = (SELECT Todo.id FROM Todo WHERE Todo.id = 1 ORDER BY Todo.title DESC LIMIT 1)

             */

            return query
                .execute(on: connection)
                .all(decoding: User.self, Todo.self)
                .map { result in
                    return result.map { (user, todo) in TodoUserResponse(todo: todo, user: user) }
            }
        }
    }

    // WORKS with PostgreSQL (using subquery)
    router.get("swifql/psql/get-todos-7") { req -> EventLoopFuture<[PTodoUserResponse]> in
        return req.withNewConnection(to: .psql) { connection -> EventLoopFuture<[PTodoUserResponse]> in

            let todo1 = PTodo.as("t1")
            let joinedTodo1 = PTodo.as("joinedTodo1")
            let user = PUser.as("u")

            let query = SwifQL
                .select(user.*, todo1.*)
                .from(user.table)
                .join(.left, todo1.table, on: todo1~\.id == |(
                    SwifQL
                        .select(joinedTodo1~\.id)
                        .from(joinedTodo1.table)
                        .where(joinedTodo1~\.id == 1)
                        .orderBy(.desc(joinedTodo1~\.title))
                        .offset(0)
                        .limit(1)
                    )|
                )

            return query
                .execute(on: connection)
                .all(decoding: PUser.self, PTodo.self)
                .map { result in
                    return result.map { (user, todo) in PTodoUserResponse(todo: todo, user: user) }
            }
        }
    }

    // WORKS with PostgreSQL (using subquery, no aliases)
    router.get("swifql/psql/get-todos-8") { req -> EventLoopFuture<[PTodoUserResponse]> in
        return req.withNewConnection(to: .psql) { connection -> EventLoopFuture<[PTodoUserResponse]> in

            let query = SwifQL
                .select(PUser.table.*, PTodo.table.*)
                .from(PUser.table)
                .join(.left, PTodo.table, on: \PTodo.id == |(
                    SwifQL
                        .select(\PTodo.id)
                        .from(PTodo.table)
                        .where(\PTodo.id == 1)
                        .orderBy(.desc(\PTodo.title))
                        .offset(0)
                        .limit(1)
                    )|
                )

            /* Produces

             SELECT User.* , Todo.* FROM User LEFT JOIN Todo ON Todo.id = (SELECT Todo.id FROM Todo WHERE Todo.id = 1 ORDER BY Todo.title DESC LIMIT 1)

             */

            return query
                .execute(on: connection)
                .all(decoding: PUser.self, PTodo.self)
                .map { result in
                    return result.map { (user, todo) in PTodoUserResponse(todo: todo, user: user) }
            }
        }
    }
}

struct TodosResponse: Content {
    let todo1: Todo
    let todo2: Todo
}

struct TodoUserResponse: Content {
    let todo: Todo
    let user: User
}

struct TodoTodoUserResponse: Content {
    let todo1: Todo
    let todo2: Todo
    let user: User
}

struct PTodoUserResponse: Content {
    let todo: PTodo
    let user: PUser
}
