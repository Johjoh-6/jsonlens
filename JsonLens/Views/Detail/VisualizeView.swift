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
            Text("Visualize").font(.title2.bold()).padding([.top, .horizontal])

            if let value = document.parsedValue {
                let root = JSONTreeNode.build(key: "root", value: value)
                List([root], children: \.children) { node in
                    HStack(spacing: 6) {
                        Text(node.label)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(node.children == nil ? .primary : Color.blue)
                        Spacer()
                        Text(valueSummary(node.value))
                            .font(.system(.callout, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
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
