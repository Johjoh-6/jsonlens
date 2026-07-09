//
//  CodeGenerating.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import Foundation

enum OutputLanguage: String, CaseIterable, Identifiable {
    case go = "Go"
    case typescriptT = "TypeScript Type"
    case typescriptI = "TypeScript Interface"
    case swift = "Swift"
    case python = "Python"

    var id: String { rawValue }

    var generator: CodeGenerating {
        switch self {
        case .go:         return GoGenerator()
        case .typescriptT: return TypeScriptGenerator(mode: .type)
        case .typescriptI: return TypeScriptGenerator(mode: .interface)
        case .swift:      return SwiftGenerator()
        case .python:     return PythonGenerator()
        }
    }
}

protocol CodeGenerating {
    /// Renders the root node and every nested object type it references.
    func generate(root: TypeNode) -> String
}

// MARK: Shared helper: collects every distinct nested `TypeNode` referenced from `root`,
/// in a stable, dependency-first-ish order, so generators can emit one block per type.
extension CodeGenerating {
    func collectNodes(root: TypeNode) -> [TypeNode] {
        var seen: [String: TypeNode] = [:]
        var order: [String] = []

        func visit(_ node: TypeNode) {
            if seen[node.name] == nil {
                seen[node.name] = node
                order.append(node.name)
            }
            for field in node.fields { visit(type: field.type) }
        }
        func visit(type: FieldType) {
            switch type {
            case .object(let n): visit(n)
            case .array(let inner): visit(type: inner)
            case .optional(let inner): visit(type: inner)
            default: break
            }
        }
        visit(root)
        // Nested types first, root last reads nicer in Go/Swift
        // reorder as needed for their own idioms.
        return order.reversed().compactMap { seen[$0] }
    }
}
