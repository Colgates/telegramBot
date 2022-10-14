//
//  File.swift
//  
//
//  Created by Evgenii Kolgin on 13.10.2022.
//

import Vapor

// MARK: - Welcome
struct Response: Content, Codable {
    let similar: Similar

    enum CodingKeys: String, CodingKey {
        case similar = "Similar"
    }
}

// MARK: - Similar
struct Similar: Codable {
//    let info: [Results]
    let results: [Result]

    enum CodingKeys: String, CodingKey {
//        case info = "Info"
        case results = "Results"
    }
}

// MARK: - Results
struct Result: Codable {
    let name, type, wTeaser: String
    let wURL, yURL: String
    let yID: String

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case type = "Type"
        case wTeaser
        case wURL = "wUrl"
        case yURL = "yUrl"
        case yID
    }
}
