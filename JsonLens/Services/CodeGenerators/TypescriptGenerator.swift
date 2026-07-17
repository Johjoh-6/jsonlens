//
//  TypescriptGenerator.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//
import Foundation

// MARK: Only use for the change mode for TS
enum ModeTS:String, CaseIterable {
    case type
    case interface
    
    var header: String {
        switch self {
        case .type: return "/// Type"
        case .interface: return "/// Interface"
        }
    }
    
    var lines: String {
        switch self {
        case .type: return "type"
        case .interface: return "interface"
        }
    }
    
    
}

struct TypeScriptGenerator: CodeGenerating {
    let mode: ModeTS
    func generate(root: TypeNode) -> String {
        let nodes = collectNodes(root: root)
        return nodes.map(render).joined(separator: "\n\n")
    }

    private func render(_ node: TypeNode) -> String {
        var lines = ["\(mode.header)\n"]
        switch mode {
            case .type: lines.append("type \(node.name) = {")
            case .interface: lines.append("interface \(node.name) {")
        }
        for field in node.fields {
            let optional: Bool
            let type: FieldType
            if case .optional(let inner) = field.type { optional = true; type = inner } else { optional = false; type = field.type }
            lines.append("  \(field.name)\(optional ? "?" : ""): \(typeString(type));")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    private func typeString(_ type: FieldType) -> String {
        switch type {
        case .string: return "string"
        case .int, .double: return "number"
        case .bool:   return "boolean"
        case .null:   return "null"
        case .array(let inner): return "\(typeString(inner))[]"
        case .object(let n): return n.name
        case .optional(let inner): return "\(typeString(inner)) | null"
        }
    }
}
