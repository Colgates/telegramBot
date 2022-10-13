import telegram_vapor_bot
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

//    let tgApi: String = Environment.get("BOT_TOKEN")!
//    let connection: TGConnectionPrtcl = TGLongPollingConnection()
//    TGBot.configure(connection: connection, botId: tgApi, vaporClient: app.client)
//    try TGBot.shared.start()

    /// set level of debug if you needed
//    TGBot.log.logLevel = .error

//    DefaultBotHandlers.addHandlers(app: app, bot: TGBot.shared)
    // register routes
    try routes(app)
}
