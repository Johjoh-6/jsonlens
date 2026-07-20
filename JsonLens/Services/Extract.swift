//
//  Extract.swift
//  JsonLens
//
//  Created by Six Johann  on 20/07/2026.
//

import Foundation

enum ExtractSeparator: String, CaseIterable, Identifiable {
    case comma
    case semicolon
    case tab
    case pipe

    var id: Self { self }

    var title: String {
        switch self {
        case .comma: return "Comma (,)"
        case .semicolon: return "Semicolon (;)"
        case .tab: return "Tab"
        case .pipe: return "Pipe (|)"
        }
    }

    var value: String {
        switch self {
        case .comma: return ","
        case .semicolon: return ";"
        case .tab: return "\t"
        case .pipe: return "|"
        }
    }
}

struct ExtractSource: Identifiable {
    let path: String
    let rows: [[JSONObjectEntry]]

    var id: String { path }

    /// Keeps the JSON key order from the first occurrence of each field.
    var fieldNames: [String] {
        var seen = Set<String>()
        return rows.flatMap { $0.map(\.key) }.filter { seen.insert($0).inserted }
    }
}

enum ExtractService {
    /// Finds every array in the JSON document that contains one or more objects.
    static func sources(in value: JSONValue) -> [ExtractSource] {
        var sources: [ExtractSource] = []

        func visit(_ value: JSONValue, at path: String) {
            switch value {
            case .object(let entries):
                for entry in entries {
                    visit(entry.value, at: "\(path).\(entry.key)")
                }
            case .array(let items):
                let rows = items.compactMap { value -> [JSONObjectEntry]? in
                    guard case .object(let entries) = value else { return nil }
                    return entries
                }

                if !rows.isEmpty {
                    sources.append(ExtractSource(path: path, rows: rows))
                }

                for (index, item) in items.enumerated() {
                    visit(item, at: "\(path)[\(index)]")
                }
            default:
                break
            }
        }

        visit(value, at: "$")
        return sources
    }

    static func delimitedText(
        source: ExtractSource,
        fields: Set<String>,
        separator: ExtractSeparator
    ) -> String {
        let selectedFields = source.fieldNames.filter(fields.contains)
        guard !selectedFields.isEmpty else { return "" }

        let delimiter = separator.value
        let header = selectedFields.map { escape($0, delimiter: delimiter) }.joined(separator: delimiter)
        let dataRows = source.rows.map { row in
            selectedFields.map { field in
                let value = row.first(where: { $0.key == field })?.value
                return escape(stringValue(for: value), delimiter: delimiter)
            }
            .joined(separator: delimiter)
        }

        return ([header] + dataRows).joined(separator: "\n")
    }

    private static func stringValue(for value: JSONValue?) -> String {
        guard let value else { return "" }

        switch value {
        case .string(let text): return text
        case .number(let number): return number
        case .bool(let boolean): return boolean ? "true" : "false"
        case .null: return ""
        case .object, .array: return JSONMinifier.minify(value)
        }
    }

    /// Quotes cells containing the selected separator, a quote, or a line break.
    /// Literal quotes are represented by two quotes, as required by CSV-style formats.
    private static func escape(_ value: String, delimiter: String) -> String {
        guard value.contains(delimiter) || value.contains("\"") || value.contains("\n") || value.contains("\r") else {
            return value
        }

        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
