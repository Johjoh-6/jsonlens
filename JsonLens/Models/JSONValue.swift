//
//  JSONValue.swift
//  JsonLens
//
//  Created by Six Johann on 15/06/2026.
//

import Foundation

indirect enum JSONValue: Equatable {
    case object([JSONObjectEntry])
    case array([JSONValue])
    case string(String)
    case number(String) // kept as raw text to preserve formatting/precision
    case bool(Bool)
    case null

    var typeName: String {
        switch self {
        case .object: return "object"
        case .array:  return "array"
        case .string: return "string"
        case .number: return "number"
        case .bool:   return "bool"
        case .null:   return "null"
        }
    }
}

struct JSONObjectEntry: Equatable {
    let key: String
    let value: JSONValue
}

/// A parse error with a human-readable message plus the exact location it occurred,
/// so the UI can point at the offending line/column in the editor.
struct JSONParseError: Error, Identifiable {
    let id = UUID()
    let message: String
    let line: Int      // 1-based
    let column: Int    // 1-based
    let index: Int      // absolute character offset
}
