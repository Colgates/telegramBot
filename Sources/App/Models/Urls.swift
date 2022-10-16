//
//  File.swift
//  
//
//  Created by Evgenii Kolgin on 16.10.2022.
//

import Vapor

enum URLS {
    enum SimilarApi {
        case getSimilar(String)
        
        var url: URL? {
            var component = URLComponents()
            component.scheme = "https"
            component.host = "tastedive.com"
            component.path = path
            component.queryItems = queryItems
            return component.url
        }
        
        private var path: String {
            switch self {
            case .getSimilar:
                return "/api/similar"
            }
        }
        
        private var queryItems: [URLQueryItem] {
            switch self {
            case .getSimilar(let query):
                return [
                    URLQueryItem(name: "q", value: query),
                    URLQueryItem(name: "limit", value: "20"),
                    URLQueryItem(name: "info", value: "1"),
                    URLQueryItem(name: "k", value: "\(Environment.get("API_KEY")!)"),
                ]
            }
        }
    }

    enum DictionaryApi {
        case getDefinitions(String)
        case getPronounciations(String)
        
        var url: URL? {
            var component = URLComponents()
            component.scheme = "https"
            component.host = "api.dictionaryapi.dev"
            component.path = path
//            component.queryItems = queryItems
            return component.url
        }
        
        private var path: String {
            switch self {
            case .getDefinitions(let query):
                return "/api/v2/entries/en/\(query)"
            case .getPronounciations(let query):
                return "/api/v2/entries/en/\(query)"
            }
        }
        
//        private var queryItems: [URLQueryItem] {
//            switch self {
//            case .getDefinitions(let query):
//                return [
//                    URLQueryItem(name: "q", value: query),
//                ]
//            case .getPronounciations(let query):
//                return [
//                    URLQueryItem(name: "q", value: query),
//                ]
//            }
//        }
    }
}
