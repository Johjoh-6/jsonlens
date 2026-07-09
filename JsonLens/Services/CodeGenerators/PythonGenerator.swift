//
//  PythonGenerator.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//
import Foundation

struct PythonGenerator: CodeGenerating {
    func generate(root: TypeNode) -> String {
        let nodes = collectNodes(root: root)
        // MARK: Header for python is mandatory
        let header = "from dataclasses import dataclass\nfrom typing import Optional, List, Any\n"
        return header + "\n" + nodes.map(render).joined(separator: "\n\n")
    }

    private func render(_ node: TypeNode) -> String {
        var lines = ["@dataclass", "class \(node.name):"]
        if node.fields.isEmpty { lines.append("    pass") }
        for field in node.fields {
            lines.append("    \(field.name): \(typeString(field.type))")
        }
        return lines.joined(separator: "\n")
    }

    private func typeString(_ type: FieldType) -> String {
        switch type {
        case .string: return "str"
        case .int:    return "int"
        case .double: return "float"
        case .bool:   return "bool"
        case .null:   return "Any"
        case .array(let inner): return "List[\(typeString(inner))]"
        case .object(let n): return n.name
        case .optional(let inner): return "Optional[\(typeString(inner))]"
        }
    }
}
