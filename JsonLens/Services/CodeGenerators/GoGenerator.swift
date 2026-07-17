//
//  GoGenerator.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//
import Foundation

struct GoGenerator: CodeGenerating {
    func generate(root: TypeNode) -> String {
        let nodes = collectNodes(root: root)
        return nodes.map(render).joined(separator: "\n\n")
    }

    private func render(_ node: TypeNode) -> String {
        var lines = ["type \(node.name) struct {"]
        for field in node.fields {
            let goName = TypeModelBuilder.capitalize(field.name)
            let goType = typeString(field.type)
            /// if optional Type add `*` (pointer) in front of the type and add in json value `,omitempty`
            var json = "\(field.name)"
            if case .optional = field.type {
                json += ",omitempty"
            }
            lines.append("\t\(goName) \(goType) `json:\"\(json)\"`")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    private func typeString(_ type: FieldType) -> String {
        switch type {
        case .string: return "string"
        case .int:    return "int"
        case .double: return "float64"
        case .bool:   return "bool"
        case .null:   return "any" // or {}interface
        case .array(let inner): return "[]" + typeString(inner)
        case .object(let n): return n.name
        case .optional(let inner): return "*" + typeString(inner)
        }
    }
}
