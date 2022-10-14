//
//  BotHandlers.swift
//  
//
//  Created by Evgenii Kolgin on 13.10.2022.
//

import telegram_vapor_bot
import Vapor

final class BotHandlers {
    
    private static var commandsNames: [String] = ["/start", "/stop", "/help", "/show_buttons"]
    private static var dictionary: [String: TGChatId] = [:]
    
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
            let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "Count: \(dictionary.count)")
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func queryHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .all && !.command.names(commandsNames)) { update, bot in
            guard let message = update.message else { return }
            let chatId: TGChatId = .chat(message.chat.id)
            
            guard let query = message.text?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }


            app.client.get(getUrl(for: query)).whenComplete { result in
                switch result {
                case .success(let response):
                    guard let buffer = response.body else { return }
                    guard let data = String(buffer: buffer).data(using: .utf8) else { return }
                    
                    do {
                        let decodedData = try JSONDecoder().decode(Response.self, from: data)
                        let results = decodedData.similar.results
                        
                        var keyboard: [[TGInlineKeyboardButton]] = [[]]
                        
                        switch !results.isEmpty {
                        case true:
                            results.forEach { result in
                                let id = UUID().uuidString
                                dictionary[id] = chatId
                                let button: [TGInlineKeyboardButton] = [.init(text: result.name, callbackData: id)]
                                
                                keyboard.append(button)
                                createButtonsActionHandler(app: app, bot: bot, result: result, id: id)
                            }
                            send("Here's what I found:", chatId, bot, replyMarkup: .inlineKeyboardMarkup(.init(inlineKeyboard: keyboard)))
                        default:
                            send("Sorry we couldn't find anything for your request.", chatId, bot)
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
    
    private static func createButtonsActionHandler(app: Vapor.Application, bot: TGBotPrtcl, result: Result, id: String) {
        
        let handler = TGCallbackQueryHandler(pattern: id) { update, bot in
            guard let chatId: TGChatId = dictionary[id] else { return }
            let text = createHTML(from: result)
            send(text, chatId, bot, parseMode: .html, disableWebPagePreview: false)
        }
        bot.connection.dispatcher.add(handler)
    }
}

// MARK: - Helpers
extension BotHandlers {
    
    private static func createHTML(from result: Result) -> String {
        return """
        <strong>\(result.name)</strong>

        \(result.wTeaser)

        <a href="\(result.yURL)">YouTube Link</a>

        <a href="\(result.wURL)">Wikipedia Link</a>
        """
    }
    
    private static func getUrl(for query: String) -> URI {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "tastedive.com"
        components.path = "/api/similar"
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "5"),
            URLQueryItem(name: "info", value: "1"),
            URLQueryItem(name: "k", value: "\(Environment.get("API_KEY")!)"),
        ]
        return URI(string: components.url?.absoluteString ?? "")
    }
    
    private static func send(_ text: String, _ chatId: TGChatId, _ bot: TGBotPrtcl, parseMode: TGParseMode? = nil, disableWebPagePreview: Bool? = false, replyMarkup: TGReplyMarkup? = nil) {
        do {
            let params: TGSendMessageParams = .init(chatId: chatId, text: text, parseMode: parseMode, disableWebPagePreview: disableWebPagePreview, replyMarkup: replyMarkup)
            try bot.sendMessage(params: params)
        } catch {
            print(error)
        }
    }
    
    private static func sendAction(_ action: ChatAction, _ chatId: TGChatId, _ bot: TGBotPrtcl) {
        do {
            let params = TGSendChatActionParams(chatId: chatId, action: action.rawValue)
            try bot.sendChatAction(params: params)
        } catch {
            print(error)
        }
    }
}
