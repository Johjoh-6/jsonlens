//
//  VisualizeView.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import SwiftUI

/// A lightweight node wrapper so `JSONValue` (a value type) can drive an `OutlineGroup`,
/// which needs identity + a `children` keypath.
struct JSONTreeNode: Identifiable {
    let id = UUID()
    let label: String
    let value: JSONValue
    let children: [JSONTreeNode]?

    static func build(key: String?, value: JSONValue) -> JSONTreeNode {
        switch value {
        case .object(let entries):
            let kids = entries.map { build(key: $0.key, value: $0.value) }
            return JSONTreeNode(label: key ?? "root", value: value, children: kids.isEmpty ? nil : kids)
        case .array(let items):
            let kids = items.enumerated().map { build(key: "[\($0.offset)]", value: $0.element) }
            return JSONTreeNode(label: key ?? "root", value: value, children: kids.isEmpty ? nil : kids)
        default:
            return JSONTreeNode(label: key ?? "root", value: value, children: nil)
        }
    }
}

struct VisualizeView: View {
    @ObservedObject var document: JSONEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let value = document.parsedValue {
                legend
                let root = JSONTreeNode.build(key: "root", value: value)
                List {
                    OutlineGroup([root], id: \.id, children: \.children) { (node: JSONTreeNode) in
                        let glyph = TypeGlyph.icon(for: node.value)
                        HStack(spacing: 6) {
                            Image(systemName: glyph.symbol)
                                .foregroundStyle(glyph.color)
                                .frame(width: 16)
                            Text(node.label)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(node.children == nil ? .primary : Color.blue)
                            if case .null = node.value {
                                Text("optional")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.15), in: Capsule())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(valueSummary(node.value))
                                .font(.system(.callout, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .listStyle(.inset)
            } else if let error = document.error {
                ContentUnavailableView("Can't visualize invalid JSON", systemImage: "exclamationmark.triangle",
                                        description: Text("Line \(error.line): \(error.message)"))
            } else {
                ContentUnavailableView("Paste JSON in the editor", systemImage: "chart.bar.doc.horizontal")
            }
        }
    }

    private var legend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                legendItem(.object([])); legendItem(.array([]))
                legendItem(.string("")); legendItem(.number("0"))
                legendItem(.bool(true)); legendItem(.null)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    private func legendItem(_ sample: JSONValue) -> some View {
        let glyph = TypeGlyph.icon(for: sample)
        return HStack(spacing: 4) {
            Image(systemName: glyph.symbol).foregroundStyle(glyph.color)
            Text(glyph.label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func valueSummary(_ value: JSONValue) -> String {
        switch value {
        case .string(let s): return "\"\(s)\""
        case .number(let n): return n
        case .bool(let b): return b ? "true" : "false"
        case .null: return "null"
        case .object(let e): return "{\(e.count)}"
        case .array(let a): return "[\(a.count)]"
        }
    }
}

/// Maps a JSON value's type to a consistent icon + color, used by both the tree
/// rows and the legend above them.
private struct TypeGlyph {
    let symbol: String
    let color: Color
    let label: String

    static func icon(for value: JSONValue) -> TypeGlyph {
        switch value {
        case .object: return TypeGlyph(symbol: "curlybraces", color: .purple, label: "Object")
        case .array:  return TypeGlyph(symbol: "list.bullet.rectangle", color: .orange, label: "Array")
        case .string: return TypeGlyph(symbol: "textformat", color: .green, label: "String")
        case .number: return TypeGlyph(symbol: "number", color: .blue, label: "Number")
        case .bool:   return TypeGlyph(symbol: "checkmark.circle", color: .pink, label: "Bool")
        case .null:   return TypeGlyph(symbol: "questionmark.circle", color: .gray, label: "Null / optional")
        }
    }
}

#Preview {
    VisualizeView(document: .preview)
    .frame(width: 700, height: 600)
}
