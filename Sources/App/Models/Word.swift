//
//  Word.swift
//  
//
//  Created by Evgenii Kolgin on 15.10.2022.
//

import Foundation

// MARK: - UserElement
struct Word: Codable {
    let word: String
    let phonetics: [Phonetic]
    let meanings: [Meaning]
    let license: License
    let sourceUrls: [String]
}

// MARK: - License
struct License: Codable {
    let name: String
    let url: String
}

// MARK: - Meaning
struct Meaning: Codable {
    let partOfSpeech: String
    let definitions: [Definition]
    let synonyms, antonyms: [String]
}

// MARK: - Definition
struct Definition: Codable {
    let definition: String
//    let synonyms, antonyms: [JSONAny]
    let example: String?
}

// MARK: - Phonetic
struct Phonetic: Codable {
    let audio: String
    let sourceURL: String?
    let license: License?
    let text: String?

    enum CodingKeys: String, CodingKey {
        case audio
        case sourceURL = "sourceUrl"
        case license, text
    }
}
