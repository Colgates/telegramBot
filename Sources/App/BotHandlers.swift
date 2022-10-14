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

            app.client.get(uri(for: query)).whenComplete { result in
                switch result {
                case .success(let response):
                    guard let buffer = response.body else { return }
                    guard let data = String(buffer: buffer).data(using: .utf8) else { return }
                    
                    do {
                        let decodedData = try JSONDecoder().decode(Response.self, from: data)
                        let items = decodedData.similar.results
                        
                        switch !items.isEmpty {
                        case true:
                            let replyMarkup = createAndPopulateInlineReplyMarkup(with: items, chatId, bot)
                            
                            send("Here's what I found:", chatId, bot, message.messageId, replyMarkup)
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
    
    private static func createButtonsActionHandler(_ bot: TGBotPrtcl, _ result: Result, _ id: String) {
        
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
    
    private static func uri(for query: String) -> URI {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "tastedive.com"
        components.path = "/api/similar"
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "info", value: "1"),
            URLQueryItem(name: "k", value: "\(Environment.get("API_KEY")!)"),
        ]
        return URI(string: components.url?.absoluteString ?? "")
    }
    
    private static func send(_ text: String, _ chatId: TGChatId, _ bot: TGBotPrtcl, parseMode: TGParseMode? = nil, disableWebPagePreview: Bool? = false, _ replyToMessageId: Int? = nil, _ replyMarkup: TGReplyMarkup? = nil) {
        do {
            let params: TGSendMessageParams = .init(chatId: chatId, text: text, parseMode: parseMode, disableWebPagePreview: disableWebPagePreview, replyToMessageId: replyToMessageId, replyMarkup: replyMarkup)
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
    
    /// Description: Calculate and populate 2D array of data
    /// - Parameters:
    ///   - results: array of data reults to populate names of buttons
    ///   - chatId: chatId for callback handlers
    ///   - bot: an instance of Bot to dispatch handlers
    private static func createAndPopulateInlineReplyMarkup(with items: [Result], _ chatId: TGChatId, _ bot: TGBotPrtcl) -> TGReplyMarkup {
        let itemPerRow = 2 // items per row
        let rows = Int((Double(items.count) / Double(itemPerRow)).rounded()) // number of rows

        var keyboard:[[TGInlineKeyboardButton]] = []
        var count = 0 // variable to iterate through items array
        for row in 0...rows {
            keyboard.append([TGInlineKeyboardButton]()) // append empty array
            for _ in 0..<itemPerRow {
                if count < items.count {
                    let id = UUID().uuidString // create an id for callback
                    dictionary[id] = chatId // store id and chatid in dictionary
                    let item = items[count] // single item
                    let button = TGInlineKeyboardButton(text: item.name, callbackData: id)
                    keyboard[row].append(button)
                    createButtonsActionHandler(bot, item, id)
                    count += 1
                }
            }
        }
        let replyMarkup: TGReplyMarkup = .inlineKeyboardMarkup(.init(inlineKeyboard: keyboard))
        return replyMarkup
    }
}
