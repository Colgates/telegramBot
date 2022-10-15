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
        infoHandler(app: app, bot: bot)
        helpHandler(app: app, bot: bot)
        pronounceHandler(app: app, bot: bot)
        queryHandler(app: app, bot: bot)
    }
    
    private static func defineHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let command = "/define"
        let handler = TGMessageHandler(filters: .command.names([command])) { update, bot in
            guard let message = update.message else { return }
            let chatId = getChatID(from: message)
            
            if var query = message.text, query != command {
                query.replaceSelf("\(command) ", "")
                
                guard let query = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
                let url = "https://api.dictionaryapi.dev/api/v2/entries/en/\(query)"
                
                getResourceOf(type: [Word].self, for: url, app) { result in
                    
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
            } else {
                send("Please send me a message like: \(command) word", chatId, bot, message.messageId)
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func diceHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/dice"])) { update, bot in
            guard let message = update.message else { return }
            let chatId = getChatID(from: message)
            
            let replyMarkup: TGReplyMarkup = createAndPopulateInlineReplyMarkup(with: Emoji.allCases, chatId, bot, itemsPerRow: 3)
            send("Choose what you want:", chatId, bot, message.messageId, replyMarkup: replyMarkup)
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
    
    private static func infoHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let command = "/info"
        let handler = TGMessageHandler(filters: .command.names([command])) { update, bot in
            
            guard let message = update.message else { return }
            let chatId = getChatID(from: message)
            
            if var query = message.text, query != command {
                query.replaceSelf("\(command) ", "")
                
                getResourceOf(type: Response.self, for: urlString(for: query), app) { result in
                    switch result {
                    case .success(let data):
                        let items = data.similar.info
                        
                        switch !items.isEmpty {
                        case true:
                            guard let item = items.first else { return }
                            let text = createHTML(from: item)
                            send(text, chatId, bot, parseMode: .html, message.messageId)
                            
                        default:
                            send("Sorry we couldn't find anything for your request.", chatId, bot, message.messageId)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            } else {
                send("Please send me a message like: \(command) word", chatId, bot, message.messageId)
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func pronounceHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let command = "/pronounce"
        let handler = TGMessageHandler(filters: .command.names([command])) { update, bot in
            guard let message = update.message else { return }
            let chatId = getChatID(from: message)
            if var query = message.text, query != command {
                query.replaceSelf("\(command) ", "")
                
                guard let query = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
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
            } else {
                send("Please send me a message like: \(command) word", chatId, bot, message.messageId)
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func queryHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .text && !.command) { update, bot in
            guard let message = update.message else { return }
            let chatId = getChatID(from: message)
            guard let query = message.text else { return }
            
            getResourceOf(type: Response.self, for: urlString(for: query), app) { result in
                switch result {
                case .success(let data):
                    let items = data.similar.results.shuffled()
                    let sliceOfItems = items.prefix(10).shuffled()
                    switch !items.isEmpty {
                    case true:
                        let replyMarkup = createAndPopulateInlineReplyMarkup(with: sliceOfItems, chatId, bot, itemsPerRow: 2)
                        
                        send("Here's what I found:", chatId, bot, message.messageId, replyMarkup: replyMarkup)
                    default:
                        send("Sorry we couldn't find anything for your request.", chatId, bot, message.messageId)
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
        var description: String
        if let temp = result.wTeaser, temp != "" {
            description = temp
        } else {
            description = "No description"
        }
        
        return """
            <strong>\(result.name)</strong>
            
            \(description)
            
            <a href="\(result.yURL ?? "")">\(result.yURL == nil ? "": "YouTube Link")</a>
            
            <a href="\(result.wURL ?? "")">\(result.wURL == nil ? "": "Wikipedia Link")</a>
            """
    }
    
    private static func urlString(for query: String) -> String {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "tastedive.com"
        components.path = "/api/similar"
        components.queryItems = [
            URLQueryItem(name: "q", value: query.replacingOccurrences(of: " ", with: "+")),
            //            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "info", value: "1"),
            URLQueryItem(name: "k", value: "\(Environment.get("API_KEY")!)"),
        ]
        return components.url?.absoluteString ?? ""
    }
    
    private static func send(_ text: String, _ chatId: TGChatId, _ bot: TGBotPrtcl, parseMode: TGParseMode? = nil, disableWebPagePreview: Bool? = false, _ replyToMessageId: Int? = nil, replyMarkup: TGReplyMarkup? = nil) {
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
    
    private static func sendDice(_ emojiName: String, _ chatId: TGChatId, _ bot: TGBotPrtcl) {
        do {
            let params: TGSendDiceParams = .init(chatId: chatId, emoji: emojiName)
            try bot.sendDice(params: params)
        } catch {
            print(error)
        }
    }
    
    /// Description: Calculate and populate 2D array of data
    /// - Parameters:
    ///   - results: array of data reults to populate names of buttons
    ///   - chatId: chatId for callback handlers
    ///   - bot: an instance of Bot to dispatch handlers
    private static func createAndPopulateInlineReplyMarkup(with items: [Repliable], _ chatId: TGChatId, _ bot: TGBotPrtcl, itemsPerRow: Int) -> TGReplyMarkup {
        
        let numOfRows = divideRoundUp(n: items.count, d: itemsPerRow)
        
        var keyboard:[[TGInlineKeyboardButton]] = []
        var count = 0 // counter to iterate through items array
        for row in 0...numOfRows {
            keyboard.append([TGInlineKeyboardButton]()) // append empty array
            for _ in 0..<itemsPerRow {
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
    
    private static func createButtonsActionHandler(_ bot: TGBotPrtcl, _ object: Repliable, _ id: String) {
        let handler = TGCallbackQueryHandler(pattern: id) { update, bot in
            guard let chatId: TGChatId = dictionary[id] else { return }
            
            switch object {
            case is Item:
                guard let item = object as? Item else { return }
                let text = createHTML(from: item)
                send(text, chatId, bot, parseMode: .html)
            case is Emoji:
                guard let emoji = object as? Emoji else { return }
                sendDice(emoji.name, chatId, bot)
            default:
                break
            }
            // close callback
            let callbackParams: TGAnswerCallbackQueryParams = .init(callbackQueryId: update.callbackQuery?.id ?? "0")
            try bot.answerCallbackQuery(params: callbackParams)
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
    
    private static func getChatID(from message: TGMessage) -> TGChatId {
        .chat(message.chat.id)
    }
    
    private static func divideRoundUp(n: Int, d: Int) -> Int {
        return n / d + (n % d == 0 ? 0 : 1)
    }
}


