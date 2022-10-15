//
//  Emoji.swift
//  
//
//  Created by Evgenii Kolgin on 15.10.2022.
//

import Foundation

enum Emoji: CaseIterable, Repliable {
    case dice
    case darts
    case bowling
    case basketball
    case football
    case slotmachine
    
    var name: String {
        switch self {
        case .dice:
            return "🎲"
        case .darts:
            return "🎯"
        case .bowling:
            return "🎳"
        case .basketball:
            return "🏀"
        case .football:
            return "⚽"
        case .slotmachine:
            return "🎰"
        }
    }
}
