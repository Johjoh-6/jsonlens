//
//  SwiftGenerator.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//
import Foundation

struct SwiftGenerator: CodeGenerating {
    func generate(root: TypeNode) -> String {
        let nodes = collectNodes(root: root)
        return nodes.map(render).joined(separator: "\n\n")
    }

    private func render(_ node: TypeNode) -> String {
        // MARK: `Codable` keyword for easy use of `JSONEncoder`
        var lines = ["struct \(node.name): Codable {"]
        for field in node.fields {
            lines.append("    let \(field.name): \(typeString(field.type))")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    private func typeString(_ type: FieldType) -> String {
        switch type {
        case .string: return "String"
        case .int:    return "Int"
        case .double: return "Double"
        case .bool:   return "Bool"
        case .null:   return "String?" // best-effort guess for always-null fields
        case .array(let inner): return "[\(typeString(inner))]"
        case .object(let n): return n.name
        case .optional(let inner): return "\(typeString(inner))?"
        }
    }
}
