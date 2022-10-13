import Vapor

struct HelloResponse: Content {
    var name: String
}

struct User: Content, Codable {
    let id: Int
    let name, company, email: String
    let avatar: String
}

func routes(_ app: Application) throws {
    
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("hello", "world") { req -> String in
        return "The new Hello world!"
    }
    
    app.get("hello", ":name") { req -> HelloResponse in
        guard let name = req.parameters.get("name") else { throw Abort(.badRequest) }
        guard name != "world" else { throw Abort(.badRequest) }
        return HelloResponse(name: name)
    }
    
    app.get("users") { req -> EventLoopFuture<[User]> in
        let uri: URI = URI("https://json-srvr.onrender.com/users")
        return req.client.get(uri).flatMapThrowing { response in
            guard response.status == .ok else { throw Abort(.badRequest) }
            guard let buffer = response.body else { throw Abort(.badRequest) }
            guard let data = String(buffer: buffer).data(using: .utf8) else { throw Abort(.badRequest) }
            
            do {
                return try JSONDecoder().decode([User].self, from: data)
            } catch {
                throw Abort(.badRequest)
            }
        }
    }
}
