//
//  JSONParser.swift
//  JsonLens
//
//  Created by Six Johann on 15/06/2026.
//

import Foundation

/// A small hand-rolled JSON parser.
///
/// We don't use `JSONSerialization` because it can't tell us *where* a syntax error
/// happened (no line/column), and it doesn't preserve key order !!! — both of which the
/// "Format Checker" and "Convert to Type" tools depend on.
struct JSONParser {

    private let scalars: [UnicodeScalar]
    private var pos: Int = 0
    private var line: Int = 1
    private var column: Int = 1

    init(_ text: String) {
        self.scalars = Array(text.unicodeScalars)
    }

    static func parse(_ text: String) -> Result<JSONValue, JSONParseError> {
        var parser = JSONParser(text)
        do {
            parser.skipWhitespace()
            let value = try parser.parseValue(path: "$", locations: nil)
            parser.skipWhitespace()
            if !parser.isAtEnd {
                throw parser.error("Unexpected trailing characters after JSON value")
            }
            return .success(value)
        } catch let err as JSONParseError {
            return .failure(err)
        } catch {
            return .failure(JSONParseError(message: "Unknown parse error", line: 1, column: 1, index: 0))
        }
    }

    /// Returns the 1-based source line where each JSON path's value begins.
    /// Diffing only requests locations for documents that have already parsed successfully.
    static func lineNumbers(in text: String) -> [String: Int] {
        var parser = JSONParser(text)
        let locations = SourceLocations()

        do {
            parser.skipWhitespace()
            _ = try parser.parseValue(path: "$", locations: locations)
            parser.skipWhitespace()
            return parser.isAtEnd ? locations.lines : [:]
        } catch {
            return [:]
        }
    }

    private final class SourceLocations {
        var lines: [String: Int] = [:]
    }

    // MARK: - Cursor helpers

    private var isAtEnd: Bool { pos >= scalars.count }

    private func peek() -> UnicodeScalar? { isAtEnd ? nil : scalars[pos] }

    @discardableResult
    private mutating func advance() -> UnicodeScalar {
        let c = scalars[pos]
        pos += 1
        if c == "\n" {
            line += 1
            column = 1
        } else {
            column += 1
        }
        return c
    }

    private func error(_ message: String) -> JSONParseError {
        JSONParseError(message: message, line: line, column: column, index: pos)
    }

    private mutating func skipWhitespace() {
        while let c = peek(), c == " " || c == "\t" || c == "\n" || c == "\r" {
            advance()
        }
    }

    private mutating func expect(_ ch: UnicodeScalar, context: String) throws {
        guard let c = peek(), c == ch else {
            throw error("Expected '\(ch)' \(context)")
        }
        advance()
    }

    // MARK: - Value parsing
    /// Important: The mutation keyword is mandatory. Since we need to mutate the struct value (immutable by default in Swift)

    private mutating func parseValue(path: String, locations: SourceLocations?) throws -> JSONValue {
        skipWhitespace()
        locations?.lines[path] = line
        guard let c = peek() else {
            throw error("Unexpected end of input, expected a value")
        }
        switch c {
        case "{": return try parseObject(path: path, locations: locations)
        case "[": return try parseArray(path: path, locations: locations)
        case "\"": return .string(try parseStringLiteral())
        case "t", "f": return try parseBool()
        case "n": return try parseNull()
        case "-", "0"..."9": return try parseNumber()
        default:
            throw error("Unexpected character '\(String(c))' while looking for a value")
        }
    }

    private mutating func parseObject(path: String, locations: SourceLocations?) throws -> JSONValue {
        try expect("{", context: "to start object")
        var entries: [JSONObjectEntry] = []
        skipWhitespace()
        if peek() == "}" { advance(); return .object(entries) }

        while true {
            skipWhitespace()
            guard peek() == "\"" else {
                throw error("Expected a string key in object")
            }
            let key = try parseStringLiteral()
            skipWhitespace()
            try expect(":", context: "after object key '\(key)'")
            let value = try parseValue(path: "\(path).\(key)", locations: locations)
            entries.append(JSONObjectEntry(key: key, value: value))
            skipWhitespace()
            guard let c = peek() else {
                throw error("Unexpected end of input inside object")
            }
            if c == "," {
                advance()
                skipWhitespace()
                if peek() == "}" {
                    // trailing comma — not valid JSON, surface it precisely
                    throw error("Trailing comma is not allowed before '}'")
                }
                continue
            } else if c == "}" {
                advance()
                break
            } else {
                throw error("Expected ',' or '}' in object")
            }
        }
        return .object(entries)
    }

    private mutating func parseArray(path: String, locations: SourceLocations?) throws -> JSONValue {
        try expect("[", context: "to start array")
        var items: [JSONValue] = []
        skipWhitespace()
        if peek() == "]" { advance(); return .array(items) }

        while true {
            let value = try parseValue(path: "\(path)[\(items.count)]", locations: locations)
            items.append(value)
            skipWhitespace()
            guard let c = peek() else {
                throw error("Unexpected end of input inside array")
            }
            if c == "," {
                advance()
                skipWhitespace()
                if peek() == "]" {
                    throw error("Trailing comma is not allowed before ']'")
                }
                continue
            } else if c == "]" {
                advance()
                break
            } else {
                throw error("Expected ',' or ']' in array")
            }
        }
        return .array(items)
    }

    private mutating func parseStringLiteral() throws -> String {
        try expect("\"", context: "to start string")
        var result = String.UnicodeScalarView()
        while true {
            guard let c = peek() else {
                throw error("Unterminated string literal")
            }
            if c == "\"" {
                advance()
                break
            }
            if c == "\\" {
                advance()
                guard let esc = peek() else { throw error("Unterminated escape sequence") }
                switch esc {
                case "\"": result.append("\""); advance()
                case "\\": result.append("\\"); advance()
                case "/":  result.append("/");  advance()
                case "b":  result.append(UnicodeScalar(8));  advance()
                case "f":  result.append(UnicodeScalar(12)); advance()
                case "n":  result.append("\n"); advance()
                case "r":  result.append("\r"); advance()
                case "t":  result.append("\t"); advance()
                case "u":
                    advance()
                    var hex = ""
                    for _ in 0..<4 {
                        guard let h = peek(), h.properties.isHexDigit else {
                            throw error("Invalid unicode escape")
                        }
                        hex.unicodeScalars.append(h)
                        advance()
                    }
                    guard let code = UInt32(hex, radix: 16), let scalar = UnicodeScalar(code) else {
                        throw error("Invalid unicode escape value")
                    }
                    result.append(scalar)
                default:
                    throw error("Invalid escape character '\\\(String(esc))'")
                }
            } else if c.value < 0x20 {
                throw error("Control character in string literal must be escaped")
            } else {
                result.append(c)
                advance()
            }
        }
        return String(result)
    }

    private mutating func parseBool() throws -> JSONValue {
        if matchLiteral("true") { return .bool(true) }
        if matchLiteral("false") { return .bool(false) }
        throw error("Invalid literal, expected 'true' or 'false'")
    }

    private mutating func parseNull() throws -> JSONValue {
        if matchLiteral("null") { return .null }
        throw error("Invalid literal, expected 'null'")
    }

    private mutating func matchLiteral(_ literal: String) -> Bool {
        let start = pos
        let startLine = line
        let startCol = column
        for expected in literal.unicodeScalars {
            guard let c = peek(), c == expected else {
                pos = start; line = startLine; column = startCol
                return false
            }
            advance()
        }
        return true
    }

    private mutating func parseNumber() throws -> JSONValue {
        var text = ""
        if peek() == "-" { text.unicodeScalars.append(advance()) }
        guard let first = peek(), ("0"..."9").contains(first) else {
            throw error("Invalid number literal")
        }
        if first == "0" {
            text.unicodeScalars.append(advance())
        } else {
            while let c = peek(), ("0"..."9").contains(c) { text.unicodeScalars.append(advance()) }
        }
        if peek() == "." {
            text.unicodeScalars.append(advance())
            guard let d = peek(), ("0"..."9").contains(d) else {
                throw error("Expected digit after decimal point")
            }
            while let c = peek(), ("0"..."9").contains(c) { text.unicodeScalars.append(advance()) }
        }
        if let e = peek(), e == "e" || e == "E" {
            text.unicodeScalars.append(advance())
            if let s = peek(), s == "+" || s == "-" { text.unicodeScalars.append(advance()) }
            guard let d = peek(), ("0"..."9").contains(d) else {
                throw error("Expected digit in exponent")
            }
            while let c = peek(), ("0"..."9").contains(c) { text.unicodeScalars.append(advance()) }
        }
        return .number(text)
    }
}
