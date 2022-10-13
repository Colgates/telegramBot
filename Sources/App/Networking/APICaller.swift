//
//  File.swift
//  
//
//  Created by Evgenii Kolgin on 13.10.2022.
//

import Foundation

enum NetworkError: Error {
    case badURL(String)
    case networkError(Error)
    case decodingError(Error)
    case errorResponse(String)
}

class APIClient {
    
    private static let baseURL = "https://api.dictionaryapi.dev/api/v2/entries/en/"
    
    static func fetchDefiniton(for word: String, completion: @escaping (Result<[Response], NetworkError>) -> Void) {
        guard let url = URL(string: baseURL + word) else { return completion(.failure(NetworkError.badURL("Something wrong with URL")))}
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    if let data = data {
                        do {
                            let results = try JSONDecoder().decode([Response].self, from: data)
                            completion(.success(results))
                        } catch {
                            completion(.failure(.decodingError(error)))
                        }
                    }
                case 404:
                    if let data = data {
                        do {
                            let results = try JSONDecoder().decode(ErrorResponse.self, from: data)
                            completion(.failure(NetworkError.errorResponse(results.message)))
                        } catch {
                            completion(.failure(.decodingError(error)))
                        }
                    }
                default:
                    break
                }
            }
        }
        .resume()
    }
}
