//
//  TypeModel.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import Foundation

/// A field's inferred type. `optional` marks a field that was missing or `null`
/// in at least one sampled element (relevant when the root is an array of objects).
indirect enum FieldType: Equatable {
    case string
    case int
    case double
    case bool
    case null
    case array(FieldType)
    case object(TypeNode)
    case optional(FieldType)
}

struct TypeField: Equatable {
    let name: String
    let type: FieldType
}

struct TypeNode: Equatable {
    let name: String
    let fields: [TypeField]
}

/// Walks a `JSONValue` tree and infers a nested `TypeNode` model that every
/// language generator (Go/TS/Swift/Python ...) renders independently.
enum TypeModelBuilder {

    static func build(from json: JSONValue, rootName: String) -> TypeNode? {
        switch json {
        case .object:
            return node(for: json, name: rootName)
        case .array(let items):
            // Merge all object elements into one shape; non-object elements are ignored
            // for struct purposes (there's nothing to name their fields after).
            let objects = items.filter { if case .object = $0 { return true } else { return false } }
            guard !objects.isEmpty else { return nil }
            return mergedNode(for: objects, name: singularize(rootName))
        default:
            return nil
        }
    }

    private static func node(for value: JSONValue, name: String) -> TypeNode? {
        guard case .object(let entries) = value else { return nil }
        var fields: [TypeField] = []
        for entry in entries {
            let type = fieldType(for: entry.value, keyHint: entry.key)
            fields.append(TypeField(name: entry.key, type: type))
        }
        return TypeNode(name: capitalize(name), fields: fields)
    }

    private static func mergedNode(for objects: [JSONValue], name: String) -> TypeNode? {
        var order: [String] = []
        var typesByKey: [String: [FieldType]] = [:]
        var presenceCount: [String: Int] = [:]

        for obj in objects {
            guard case .object(let entries) = obj else { continue }
            var seenKeys = Set<String>()
            for entry in entries {
                if !typesByKey.keys.contains(entry.key) {
                    order.append(entry.key)
                }
                typesByKey[entry.key, default: []].append(fieldType(for: entry.value, keyHint: entry.key))
                seenKeys.insert(entry.key)
            }
            for key in seenKeys { presenceCount[key, default: 0] += 1 }
        }

        var fields: [TypeField] = []
        for key in order {
            let candidates = typesByKey[key] ?? []
            var merged = candidates.first ?? .null
            for t in candidates.dropFirst() { merged = unify(merged, t) }
            if presenceCount[key, default: 0] < objects.count {
                merged = .optional(merged)
            }
            fields.append(TypeField(name: key, type: merged))
        }
        return TypeNode(name: capitalize(name), fields: fields)
    }

    private static func fieldType(for value: JSONValue, keyHint: String) -> FieldType {
        switch value {
        case .string: return .string
        case .bool:   return .bool
        case .null:   return .null
        case .number(let raw):
            return (raw.contains(".") || raw.lowercased().contains("e")) ? .double : .int
        case .array(let items):
            guard let first = items.first else { return .array(.string) } // empty array: guess string
            let objects = items.filter { if case .object = $0 { return true } else { return false } }
            if !objects.isEmpty, case .object = first {
                let node = mergedNode(for: objects, name: singularize(keyHint)) ?? TypeNode(name: capitalize(singularize(keyHint)), fields: [])
                return .array(.object(node))
            }
            var elementType = fieldType(for: first, keyHint: keyHint)
            for item in items.dropFirst() { elementType = unify(elementType, fieldType(for: item, keyHint: keyHint)) }
            return .array(elementType)
        case .object:
            guard let node = node(for: value, name: keyHint) else { return .object(TypeNode(name: capitalize(keyHint), fields: [])) }
            return .object(node)
        }
    }

    // MARK: Combine two observed types for the same field into one (e.g. int + double -> double,
    /// anything + null -> optional(anything)).
    private static func unify(_ a: FieldType, _ b: FieldType) -> FieldType {
        if a == b { return a }
        switch (a, b) {
        case (.null, let other), (let other, .null):
            return makeOptional(other)
        case (.int, .double), (.double, .int):
            return .double
        case (.optional(let inner), let other), (let other, .optional(let inner)):
            return .optional(unify(inner, other))
        default:
            return a // divergent types (e.g. string vs bool) — keep first, generators can flag as `Any`/`interface{}`
        }
    }

    /// Might never be use
    static func singularize(_ name: String) -> String {
        if name.hasSuffix("ies") { return String(name.dropLast(3)) + "y" }
        if name.hasSuffix("s") && !name.hasSuffix("ss") { return String(name.dropLast()) }
        return name
    }

    static func capitalize(_ name: String) -> String {
        let cleaned = name.split(separator: "_").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
        guard let first = cleaned.first else { return "Root" }
        return first.uppercased() + cleaned.dropFirst()
    }
    
    /// Wraps a type as optional, unless it's already nullable in some form (`.optional` or bare `.null`) — prevents ever producing a nested double-optional like
    /// `.optional(.optional(...))` or `.optional(.null)`
    /// which generators would render as a double marker (`String??`, or invalid syntax in languages ).
    private static func makeOptional(_ type: FieldType) -> FieldType {
        switch type {
        case .optional, .null:
            return type
        default:
            return .optional(type)
        }
    }
}
