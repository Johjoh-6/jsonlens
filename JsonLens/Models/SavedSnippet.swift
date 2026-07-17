//
//  SavedSnippet.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import Foundation
import SwiftData

/// A JSON snippet history model
@Model
final class SavedSnippet {
    var name: String
    var jsonText: String
    var createdAt: Date

    init(name: String, jsonText: String, createdAt: Date = .now) {
        self.name = name
        self.jsonText = jsonText
        self.createdAt = createdAt
    }
}
