//
//  JSONType.swift
//  JsonLens
//
//  Created by Six Johann on 15/06/2026.
//

import Foundation

/// Represents the possible types of JSON values
enum JSONType: String, CaseIterable {
    case object   // { "key": "value" }
    case array    // [1, 2, 3]
    case string   // "hello"
    case number   // 42 or 3.14
    case bool     // true or false
    case null     // null
}
