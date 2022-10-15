//
//  Response.swift
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
    let info: [Item]
    let results: [Item]

    enum CodingKeys: String, CodingKey {
        case info = "Info"
        case results = "Results"
    }
}

// MARK: - Results
struct Item: Codable {
    let name: String
    let type: String
    let wTeaser: String?
    let wURL: String?
    let yURL: String?
    let yID: String?

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case type = "Type"
        case wTeaser
        case wURL = "wUrl"
        case yURL = "yUrl"
        case yID
    }
}
