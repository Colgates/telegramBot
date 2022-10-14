//
//  BotHandlers.swift
//  
//
//  Created by Evgenii Kolgin on 13.10.2022.
//

import telegram_vapor_bot
import Vapor

final class BotHandlers {
    
    private static var commandsNames: [String] = ["/start", "/stop", "/help"]
    
    static func addHandlers(app: Vapor.Application, bot: TGBotPrtcl) {
        startHandler(app: app, bot: bot)
        stopHandler(app: app, bot: bot)
        helpHandler(app: app, bot: bot)
        queryHandler(app: app, bot: bot)
    }
    
    private static func startHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/start"])) { update, bot in
            
            let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "This bot can help to get similar things, just send me something: a book, a movie or a music band...")
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func stopHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/stop"])) { update, bot in
            
            let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "This bot can help to get similar things, just send me something: a book, a movie or a music band...")
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func helpHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/help"])) { update, bot in
            
            let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "This bot can help to get similar things, just send me something: a book, a movie or a music band...")
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func queryHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .all && !.command.names(commandsNames)) { update, bot in
            
            let chatId: TGChatId = .chat(update.message!.chat.id)
            
            guard let query = update.message?.text?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }

            let eventLoop = app.eventLoopGroup.next()
            let request = Request(application: app, method: .GET, url: getUrl(for: query), on: eventLoop)
            
            request.client.get(request.url).whenComplete { result in
                
                switch result {
                case .success(let response):
                    guard let buffer = response.body else { return }
                    guard let data = String(buffer: buffer).data(using: .utf8) else { return }
                    do {
                        let decodedData = try JSONDecoder().decode(Response.self, from: data)
                        let results = decodedData.similar.results
                        
                        if !results.isEmpty {
                            results.forEach { result in
                                let text = createHTML(from: result)
                                
                                let params: TGSendMessageParams = .init(chatId: chatId, text: text, parseMode: .html, disableWebPagePreview: false)
                                do {
                                    try bot.sendMessage(params: params)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                        else {
                            do {
                                let params: TGSendMessageParams = .init(chatId: chatId, text: "Sorry we couldn't find anything for your request.")
                                try bot.sendMessage(params: params)
                            } catch {
                                print(error)
                            }
                        }
                    } catch {
                        print(error)
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func createHTML(from result: Results) -> String {
        return """
        <strong>\(result.name)</strong>

        \(result.wTeaser)

        <a href="\(result.yURL)">YouTube Link</a>

        <a href="\(result.wURL)">Wikipedia Link</a>
        """
    }
    
    private static func getUrl(for q: String) -> URI {
        let baseUrl = "https://tastedive.com/api/similar"
        let query = "?q=\(q)"
        let limit = "&limit=1"
        let info = "&info=1"
        let key = Environment.get("API_KEY")!
        let apiKey = "&k=\(key)"
        let urlString = baseUrl+query+limit+info+apiKey
        print(urlString)
        return URI(string: urlString)
    }
}

