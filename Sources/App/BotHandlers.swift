//
//  BotHandlers.swift
//  
//
//  Created by Evgenii Kolgin on 13.10.2022.
//

import telegram_vapor_bot
import Vapor

final class BotHandlers {
    // TODO: - figure out how to storage ids
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
        
        let handler = TGMessageHandler(filters: .command.names([Command.define.name])) { update, bot in
            guard let message = update.message else {
                print(Abort(.custom(code: 5, reasonPhrase: "Definition message nil.")))
                return
            }
            
            let chatId = getChatID(from: message)
            
            if var query = message.text, query != Command.define.name {
                query.replaceSelf(Command.define.name, "")
                
                let url = URLS.DictionaryApi.getDefinitions(query).url
                
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
                        print(Abort(.custom(code: 4, reasonPhrase: "Failed to get a definition query. \(error.localizedDescription)")))
                    }
                }
            } else {
                send("Please send me a message like: \(Command.define.name) word", chatId, bot, message.messageId)
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func diceHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        
        // TODO: - make emoji replymarkup bigger
        
        let handler = TGMessageHandler(filters: .command.names([Command.dice.name])) { update, bot in
            guard let message = update.message else { return }
            let chatId = getChatID(from: message)
            
            let replyMarkup: TGReplyMarkup = createAndPopulateInlineReplyMarkup(with: Emoji.allCases, chatId, bot, itemsPerRow: 3)
            send("Choose what you want:", chatId, bot, message.messageId, replyMarkup)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func helpHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names([Command.help.name])) { update, bot in
            let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "Count: \(dictionary.count)")
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func infoHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        
        let handler = TGMessageHandler(filters: .command.names([Command.info.name])) { update, bot in
            
            guard let message = update.message else {
                print(Abort(.custom(code: 5, reasonPhrase: "Info message nil.")))
                return
            }
            
            let chatId = getChatID(from: message)
            
            if var query = message.text, query != Command.info.name {
                
                query.replaceSelf(Command.info.name, "")
                
                let url = URLS.SimilarApi.getSimilar(query).url
                
                getResourceOf(type: Response.self, for: url, app) { result in
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
                        print(Abort(.custom(code: 4, reasonPhrase: "Failed to get the info query. \(error.localizedDescription)")))
                    }
                }
            } else {
                send("Please send me a message like: \(Command.info.name) word", chatId, bot, message.messageId)
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func pronounceHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        
        let handler = TGMessageHandler(filters: .command.names([Command.pronounce.name])) { update, bot in
            guard let message = update.message else {
                print(Abort(.custom(code: 5, reasonPhrase: "Prononuciation message nil.")))
                return
            }
            let chatId = getChatID(from: message)
            if var query = message.text, query != Command.pronounce.name {
                query.replaceSelf(Command.pronounce.name, "")
                
                let url = URLS.DictionaryApi.getPronounciations(query).url
                
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
                        print(Abort(.custom(code: 4, reasonPhrase: "Failed to get a pronounciation query. \(error.localizedDescription)")))
                    }
                }
            } else {
                send("Please send me a message like: \(Command.pronounce.name) word", chatId, bot, message.messageId)
            }
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func queryHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        
        // TODO: - update message rather than send a new one
        
        let handler = TGMessageHandler(filters: .text && !.command) { update, bot in
            guard let message = update.message else {
                print(Abort(.custom(code: 5, reasonPhrase: "Similar query message nil.")))
                return
            }
            let chatId = getChatID(from: message)
            guard let query = message.text else { return }
            
            let url = URLS.SimilarApi.getSimilar(query).url
            getResourceOf(type: Response.self, for: url, app) { result in
                switch result {
                case .success(let data):
                    let items = data.similar.results.shuffled()
                    let sliceOfItems = items.prefix(10).shuffled()
                    switch !items.isEmpty {
                    case true:
                        let replyMarkup = createAndPopulateInlineReplyMarkup(with: sliceOfItems, chatId, bot)
                        
                        send("Here's what I found:", chatId, bot, message.messageId, replyMarkup)
                    default:
                        send("Sorry we couldn't find anything for your request.", chatId, bot, message.messageId)
                    }
                case .failure(let error):
                    print(Abort(.custom(code: 4, reasonPhrase: "Failed to get a reponse from query. \(error.localizedDescription)")))
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
    
    private static func send(_ text: String, _ chatId: TGChatId, _ bot: TGBotPrtcl, parseMode: TGParseMode? = nil, disableWebPagePreview: Bool? = false, _ replyToMessageId: Int? = nil, _ replyMarkup: TGReplyMarkup? = nil) {
        do {
            let params: TGSendMessageParams = .init(chatId: chatId, text: text, parseMode: parseMode, disableWebPagePreview: disableWebPagePreview, replyToMessageId: replyToMessageId, replyMarkup: replyMarkup)
            try bot.sendMessage(params: params)
        } catch {
            print(Abort(.custom(code: 5, reasonPhrase: "Bot failed to send a message. \(error.localizedDescription)")))
        }
    }
    
    private static func sendAction(_ action: ChatAction, _ chatId: TGChatId, _ bot: TGBotPrtcl) {
        do {
            let params = TGSendChatActionParams(chatId: chatId, action: action.rawValue)
            try bot.sendChatAction(params: params)
        } catch {
            print(Abort(.custom(code: 5, reasonPhrase: "Bot failed to send an action. \(error.localizedDescription)")))
        }
    }
    
    private static func sendDice(_ emojiName: String, _ chatId: TGChatId, _ bot: TGBotPrtcl) {
        do {
            let params: TGSendDiceParams = .init(chatId: chatId, emoji: emojiName)
            try bot.sendDice(params: params)
        } catch {
            print(Abort(.custom(code: 5, reasonPhrase: "Bot failed to send dices. \(error.localizedDescription)")))
        }
    }
    
    /// Description: Calculate and populate 2D array of data
    /// - Parameters:
    ///   - results: array of data reults to populate names of buttons
    ///   - chatId: chatId for callback handlers
    ///   - bot: an instance of Bot to dispatch handlers
    private static func createAndPopulateInlineReplyMarkup(with items: [Repliable], _ chatId: TGChatId, _ bot: TGBotPrtcl, itemsPerRow: Int = 2) -> TGReplyMarkup {
        
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
            guard let chatId: TGChatId = dictionary[id] else {
                print(Abort(.custom(code: 5, reasonPhrase: "Failed to get chatID from storage.")))
                return
            }
            
            switch object {
            case is Item:
                guard let item = object as? Item else {
                    print(Abort(.custom(code: 5, reasonPhrase: "Failed to cast object as Item")))
                    return
                }
                let text = createHTML(from: item)
                send(text, chatId, bot, parseMode: .html)
            case is Emoji:
                guard let emoji = object as? Emoji else {
                    print(Abort(.custom(code: 5, reasonPhrase: "Failed to cast object as Emoji")))
                    return
                }
                sendDice(emoji.name, chatId, bot)
            default:
                print(Abort(.custom(code: 5, reasonPhrase: "Object for button handler is undefined")))
                break
            }
            // close callback
            let callbackParams: TGAnswerCallbackQueryParams = .init(callbackQueryId: update.callbackQuery?.id ?? "0")
            try bot.answerCallbackQuery(params: callbackParams)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func getResourceOf<T:Codable>(type: T.Type, for url: URL?, _ app: Vapor.Application, completion: @escaping (Result<T, Error>) -> Void) {
        guard let urlString = url?.absoluteString else {
            completion(.failure(Abort(.custom(code: 1, reasonPhrase: "Couldn't convert url to string"))))
            return
        }
        Task {
            app.client.get(URI(string: urlString)).whenComplete { result in
                switch result {
                case .success(let response):
                    
                    guard let buffer = response.body else { return }
                    guard let data = String(buffer: buffer).data(using: .utf8) else { return }
                    
                    do {
                        let decodedData = try JSONDecoder().decode(T.self, from: data)
                        completion(.success(decodedData))
                    } catch {
                        completion(.failure(Abort(.custom(code: 3, reasonPhrase: "Failed decoding JSON"))))
                    }
                    
                case .failure(let error):
                    completion(.failure(Abort(.custom(code: 4, reasonPhrase: "Failed to get a response. \(error.localizedDescription)"))))
                }
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
