//
//  BotHandlers.swift
//  
//
//  Created by Evgenii Kolgin on 13.10.2022.
//

import telegram_vapor_bot
import Vapor

final class BotHandlers {
    
    private static var dictionary: [String: TGChatId] = [:]
    
    static func addHandlers(app: Vapor.Application, bot: TGBotPrtcl) {
        defineHandler(app: app, bot: bot)
        diceHandler(app: app, bot: bot)
        helpHandler(app: app, bot: bot)
        pronounceHandler(app: app, bot: bot)
        queryHandler(app: app, bot: bot)
    }
    
    private static func defineHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/define"])) { update, bot in
            guard let message = update.message else { return }
            guard var query = message.text else { return }
            if let range = query.range(of: "/define ") {
                query.removeSubrange(range)
            }
            let chatId: TGChatId = .chat(message.chat.id)
            let url = "https://api.dictionaryapi.dev/api/v2/entries/en/\(query)"
            
            getResourceOf(type: [Word].self, for: url, app) { result in
                print("define")
                switch result {
                case .success(let data):
                    guard let array = data.first else { return }
                    let meanings = array.meanings
                    
                    var text = ""
                    var count = 1
                    
                    meanings.forEach { meaning in
                        meaning.definitions.forEach { element in
                            text += "\n\(count). \(element.definition)"
                            count += 1
                        }
                    }
                    
                    send(text, chatId, bot, parseMode: .html, message.messageId)
                    
                case .failure(let error):
                    print(error)
                }
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func diceHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/dice"])) { update, bot in
            let params: TGSendDiceParams = .init(chatId: .chat(update.message!.chat.id))
            try bot.sendDice(params: params)
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
    
    private static func pronounceHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/pronounce"])) { update, bot in
                guard let message = update.message else { return }
                guard var query = message.text else { return }
                if let range = query.range(of: "/pronounce ") {
                    query.removeSubrange(range)
                }
                let chatId: TGChatId = .chat(message.chat.id)
                let url = "https://api.dictionaryapi.dev/api/v2/entries/en/\(query)"
                
                getResourceOf(type: [Word].self, for: url, app) { result in
                    switch result {
                    case .success(let data):
                        guard let array = data.first else { return }
                        array.phonetics.forEach { element in
                            if element.audio != "" {
                                do {
                                    let params: TGSendAudioParams = .init(chatId: chatId, audio: .url(element.audio))
                                    try bot.sendAudio(params: params)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func queryHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .text && !.command) { update, bot in
            guard let message = update.message else { return }
            let chatId: TGChatId = .chat(message.chat.id)
            
            guard let query = message.text else { return }

            getResourceOf(type: Response.self, for: urlString(for: query), app) { result in
                switch result {
                case .success(let data):
                    let items = data.similar.results
                    
                    switch !items.isEmpty {
                    case true:
                        let replyMarkup = createAndPopulateInlineReplyMarkup(with: items, chatId, bot)
                        
                        send("Here's what I found:", chatId, bot, message.messageId, replyMarkup)
                    default:
                        send("Sorry we couldn't find anything for your request.", chatId, bot)
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
        bot.connection.dispatcher.add(handler)
    }
}

// MARK: - Helpers
extension BotHandlers {
    
    private static func createHTML(from result: Item) -> String {
        return """
        <strong>\(result.name)</strong>

        \(result.wTeaser)

        <a href="\(result.yURL)">YouTube Link</a>

        <a href="\(result.wURL)">Wikipedia Link</a>
        """
    }
    
    private static func urlString(for query: String) -> String {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "tastedive.com"
        components.path = "/api/similar"
        components.queryItems = [
            URLQueryItem(name: "q", value: query.replacingOccurrences(of: " ", with: "+")),
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "info", value: "1"),
            URLQueryItem(name: "k", value: "\(Environment.get("API_KEY")!)"),
        ]
        return components.url?.absoluteString ?? ""
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
    private static func createAndPopulateInlineReplyMarkup(with items: [Item], _ chatId: TGChatId, _ bot: TGBotPrtcl) -> TGReplyMarkup {
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
    
    private static func createButtonsActionHandler(_ bot: TGBotPrtcl, _ result: Item, _ id: String) {
        let handler = TGCallbackQueryHandler(pattern: id) { update, bot in
            guard let chatId: TGChatId = dictionary[id] else { return }
            let text = createHTML(from: result)
            send(text, chatId, bot, parseMode: .html)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func getResourceOf<T:Codable>(type: T.Type, for url: String, _ app: Vapor.Application, completion: @escaping (Result<T, Error>) -> Void) {
        let uri = URI(string: url)
        app.client.get(uri).whenComplete { result in
            switch result {
            case .success(let response):
                
                guard let buffer = response.body else { return }
                guard let data = String(buffer: buffer).data(using: .utf8) else { return }
                
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedData))
                } catch {
                    completion(.failure(error))
                    print(error)
                }
                
            case .failure(let error):
                completion(.failure(error))
                print(error)
            }
        }
    }
}
