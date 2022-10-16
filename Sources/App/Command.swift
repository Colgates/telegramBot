//
//  Command.swift
//  
//
//  Created by Evgenii Kolgin on 16.10.2022.
//

import Foundation

enum Command {
    case define
    case dice
    case info
    case help
    case pronounce
    
    var name: String {
        switch self {
        case .define:
            return "/define"
        case .dice:
            return "/dice"
        case .info:
            return "/info"
        case .help:
            return "/help"
        case .pronounce:
            return "/pronounce"
        }
    }
}
