//
//  JSONFormating.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import Foundation

// MARK: - Re-serializes a parsed `JSONValue` back to nicely indented text.
enum JSONPrettyPrinter {
    static func print(_ value: JSONValue, indent: Int = 0) -> String {
        let pad = String(repeating: "  ", count: indent)
        let childPad = String(repeating: "  ", count: indent + 1)
        switch value {
        case .object(let entries):
            if entries.isEmpty { return "{}" }
            let body = entries.map { "\(childPad)\"\($0.key)\": \(print($0.value, indent: indent + 1))" }
                .joined(separator: ",\n")
            return "{\n\(body)\n\(pad)}"
        case .array(let items):
            if items.isEmpty { return "[]" }
            let body = items.map { "\(childPad)\(print($0, indent: indent + 1))" }.joined(separator: ",\n")
            return "[\n\(body)\n\(pad)]"
        case .string(let s): return "\"\(s.replacingOccurrences(of: "\"", with: "\\\""))\""
        case .number(let n): return n
        case .bool(let b): return b ? "true" : "false"
        case .null: return "null"
        }
    }
}

// MARK: - Re-serializes a parsed `JSONValue` to the shortest valid form — no whitespace at all.
enum JSONMinifier {
    static func minify(_ value: JSONValue) -> String {
        switch value {
        case .object(let entries):
            let body = entries.map { "\"\($0.key)\":\(minify($0.value))" }.joined(separator: ",")
            return "{\(body)}"
        case .array(let items):
            let body = items.map { minify($0) }.joined(separator: ",")
            return "[\(body)]"
        case .string(let s): return "\"\(s.replacingOccurrences(of: "\"", with: "\\\""))\""
        case .number(let n): return n
        case .bool(let b): return b ? "true" : "false"
        case .null: return "null"
        }
    }
}

// MARK: - Quick-glance stats shown in the editor pane's Info popover.
struct JSONStats {
    let lines: Int
    let characters: Int
    let bytes: Int
    let maxDepth: Int?
    let topLevelCount: Int?

    static func compute(text: String, value: JSONValue?) -> JSONStats {
        let lines = text.isEmpty ? 1 : text.reduce(1) { $1 == "\n" ? $0 + 1 : $0 }
        var depth: Int? = nil
        var topLevel: Int? = nil
        if let value {
            depth = maxDepth(of: value)
            switch value {
            case .object(let e): topLevel = e.count
            case .array(let a): topLevel = a.count
            default: break
            }
        }
        return JSONStats(lines: lines, characters: text.count, bytes: text.utf8.count,
                          maxDepth: depth, topLevelCount: topLevel)
    }

    private static func maxDepth(of value: JSONValue) -> Int {
        switch value {
        case .object(let entries):
            return 1 + (entries.map { maxDepth(of: $0.value) }.max() ?? 0)
        case .array(let items):
            return 1 + (items.map { maxDepth(of: $0) }.max() ?? 0)
        default:
            return 1
        }
    }
}
