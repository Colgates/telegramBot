//
//  DefaultBotHandlers.swift
//  
//
//  Created by Evgenii Kolgin on 11.10.2022.
//

import telegram_vapor_bot
import Vapor

final class DefaultBotHandlers {
    
    static func addHandlers(app: Vapor.Application, bot: TGBotPrtcl) {
        defaultHandler(app: app, bot: bot)
        commandPingHandler(app: app, bot: bot)
        commandShowButtonsHandler(app: app, bot: bot)
        buttonsActionHandler(app: app, bot: bot)
        startHandler(app: app, bot: bot)
        reverseHandler(app: app, bot: bot)
        diceHandler(app: app, bot: bot)
        usersHandler(app: app, bot: bot)
    }

    /// add handler for all messages unless command "/ping"
    private static func defaultHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: (.all && !.command.names(["/ping", "/show_buttons", "/start", "/reverse", "/users"]))) { update, bot in
            guard let messageText = update.message?.text else { return }
            let uri: URI = URI("https://api.dictionaryapi.dev/api/v2/entries/en/\(messageText)")
            let eventLoop = app.eventLoopGroup.next()
            let request = Request(application: app, method: .GET, url: uri, on: eventLoop)
            
            request.client.get(uri).whenComplete { result in
                switch result {
                case .success(let response):
                    guard let buffer = response.body else { return }
                    guard let data = String(buffer: buffer).data(using: .utf8) else { return }
                    do {
                        let decodedData = try JSONDecoder().decode([Response].self, from: data)
                        guard let definition = decodedData.first?.meanings.first?.definitions.first?.definition else { return }
                        let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: definition)
                        try bot.sendMessage(params: params)
                    } catch {
                        do {
                            let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "Sorry pal, we couldn't find definitions for the word you were looking for.")
                            try bot.sendMessage(params: params)
                        } catch {
                            print(error)
                        }
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
        bot.connection.dispatcher.add(handler)
    }

    /// add handler for command "/ping"
    private static func commandPingHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/ping"]) { update, bot in
            try update.message?.reply(text: "pong", bot: bot)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    /// add handler for command "/show_buttons" - show message with buttons
    private static func commandShowButtonsHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCommandHandler(commands: ["/show_buttons"]) { update, bot in
            guard let userId = update.message?.from?.id else { fatalError("user id not found") }
            let buttons: [[TGInlineKeyboardButton]] = [
                [.init(text: "Button 1", callbackData: "press 1"), .init(text: "Button 2", callbackData: "press 2")]
            ]
            let keyboard: TGInlineKeyboardMarkup = .init(inlineKeyboard: buttons)
            let params: TGSendMessageParams = .init(chatId: .chat(userId),
                                                    text: "Keyboard activ",
                                                    replyMarkup: .inlineKeyboardMarkup(keyboard))
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    /// add two handlers for callbacks buttons
    private static func buttonsActionHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGCallbackQueryHandler(pattern: "press 1") { update, bot in
            let params: TGAnswerCallbackQueryParams = .init(callbackQueryId: update.callbackQuery?.id ?? "0",
                                                            text: update.callbackQuery?.data  ?? "data not exist",
                                                            showAlert: nil,
                                                            url: nil,
                                                            cacheTime: nil)
            try bot.answerCallbackQuery(params: params)
        }

        let handler2 = TGCallbackQueryHandler(pattern: "press 2") { update, bot in
            let params: TGAnswerCallbackQueryParams = .init(callbackQueryId: update.callbackQuery?.id ?? "0",
                                                            text: update.callbackQuery?.data  ?? "data not exist",
                                                            showAlert: nil,
                                                            url: nil,
                                                            cacheTime: nil)
            try bot.answerCallbackQuery(params: params)
        }

        bot.connection.dispatcher.add(handler)
        bot.connection.dispatcher.add(handler2)
    }
    
    private static func startHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/start"])) { update, bot in
            
            let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "@\(bot) started. Use '/reverse some text' to reverse the text.\n")
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }
    
    private static func reverseHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/reverse"])) { update, bot in
            
            guard var messageText = update.message?.text else { return }
            let wordToRemove = "/reverse "
            if let range = messageText.range(of: wordToRemove) {
                messageText.removeSubrange(range)
            }
        
            let reversed = String(messageText.reversed())
            
            let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: reversed)
            try bot.sendMessage(params: params)
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
    
    private static func usersHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: .command.names(["/users"])) { update, bot in
            
            let uri: URI = URI("https://jsonplaceholder.typicode.com/users")
            let eventLoop = app.eventLoopGroup.next()
            let request = Request(application: app, method: .GET, url: uri, on: eventLoop)
            
            request.client.get(uri).whenComplete { result in
                switch result {
                case .success(let response):
                    guard let buffer = response.body else { return }
                    guard let data = String(buffer: buffer).data(using: .utf8) else { return }
                    do {
                        let users = try JSONDecoder().decode([User].self, from: data)
                        guard let randomUser = users.randomElement() else { return }
                        let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "\(randomUser)")
                        try bot.sendMessage(params: params)
                    } catch {
                        print(error)
                    }
                case .failure(let failure):
                    print(failure)
                }
            }
        }
        bot.connection.dispatcher.add(handler)
    }
}
