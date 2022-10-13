//
//  User.swift
//  
//
//  Created by Evgenii Kolgin on 13.10.2022.
//

import Vapor

struct User: Content, Codable {
    let id: Int
    let name, company, email: String
    let avatar: String
}
