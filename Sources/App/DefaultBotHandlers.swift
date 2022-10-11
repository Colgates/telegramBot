//
//  DefaultBotHandlers.swift
//  
//
//  Created by Evgenii Kolgin on 11.10.2022.
//

import telegram_vapor_bot
import Vapor

// MARK: - UserElement
struct User: Codable {
    let address: Address
    let id: Int
    let email, username, password: String
    let name: Name
    let phone: String
    let v: Int

    enum CodingKeys: String, CodingKey {
        case address, id, email, username, password, name, phone
        case v = "__v"
    }
}

// MARK: - Address
struct Address: Codable {
    let geolocation: Geolocation
    let city, street: String
    let number: Int
    let zipcode: String
}

// MARK: - Geolocation
struct Geolocation: Codable {
    let lat, long: String
}

// MARK: - Name
struct Name: Codable {
    let firstname, lastname: String
}

final class DefaultBotHandlers {

    static var users: [User] = []
    
    static func fetchUsers() {
//        let resource = Resource<User>(url: URL(string: "https://fakestoreapi.com/users")!)
//        Task {
            let url = URL(string: "https://fakestoreapi.com/users")
            URLSession.shared.dataTask(with: url!) { data, _, error in
                guard let data = data, error == nil else { return }
                
//            }
                do {
                    let decodedData = try JSONDecoder().decode([User].self, from: data)
                    self.users = decodedData
                } catch {
                    print(error)
                }
                
            print("here")
        }
            .resume()
    }
    
    static func addHandlers(app: Vapor.Application, bot: TGBotPrtcl) {
//        defaultHandler(app: app, bot: bot)
        commandPingHandler(app: app, bot: bot)
        commandShowButtonsHandler(app: app, bot: bot)
        buttonsActionHandler(app: app, bot: bot)
        startHandler(app: app, bot: bot)
        reverseHandler(app: app, bot: bot)
        diceHandler(app: app, bot: bot)
        customHandler(app: app, bot: bot)
    }

    /// add handler for all messages unless command "/ping"
    private static func defaultHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        let handler = TGMessageHandler(filters: (.all && !.command.names(["/ping"]))) { update, bot in
            let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "Success")
            try bot.sendMessage(params: params)
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
            if let string = update.message?.text {
                print(string)
            }
            let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "success")
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
    
    private static func customHandler(app: Vapor.Application, bot: TGBotPrtcl) {
        
        let handler = TGMessageHandler(filters: .command.names(["/users"])) { update, bot in
            let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "\(users)")
            try bot.sendMessage(params: params)
        }
        bot.connection.dispatcher.add(handler)
    }
}
