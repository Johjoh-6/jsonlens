//
//  CompareView.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import SwiftUI

struct CompareView: View {
    @ObservedObject var document: JSONEditorViewModel
    @ObservedObject var comparison: JSONEditorViewModel
    @StateObject private var viewModel = CompareViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let documentError = document.error {
                statusBanner(title: "Left JSON is invalid", error: documentError)
            } else if let comparisonError = comparison.error {
                statusBanner(title: "Right JSON is invalid", error: comparisonError)
            } else if let entries = viewModel.diffEntries(document: document, comparison: comparison) {
                let changed = entries.filter { $0.kind != .same }
                if changed.isEmpty {
                    ContentUnavailableView("No differences", systemImage: "checkmark.circle",
                                            description: Text("Both documents are structurally identical."))
                } else {
                    summaryHeader(changed)
                    List(changed) { entry in
                        DiffRow(entry: entry)
                    }
                    .listStyle(.inset)
                }
            } else {
                ContentUnavailableView("Paste JSON in both editors", systemImage: "arrow.left.arrow.right.square")
            }
        }
    }

    private func summaryHeader(_ entries: [DiffEntry]) -> some View {
        let added = entries.filter { $0.kind == .added }.count
        let removed = entries.filter { $0.kind == .removed }.count
        let changed = entries.filter { $0.kind == .changed }.count
        return HStack(spacing: 16) {
            Label("\(added) added", systemImage: "plus.circle.fill").foregroundStyle(.green)
            Label("\(removed) removed", systemImage: "minus.circle.fill").foregroundStyle(.red)
            Label("\(changed) changed", systemImage: "pencil.circle.fill").foregroundStyle(.orange)
        }
        .font(.callout)
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private func statusBanner(title: String, error: JSONParseError) -> some View {
        ContentUnavailableView(title, systemImage: "exclamationmark.triangle",
                                description: Text("Line \(error.line), column \(error.column): \(error.message)"))
    }
}

private struct DiffRow: View {
    let entry: DiffEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            icon
            VStack(alignment: .leading, spacing: 4) {
                Text("Path: \(entry.path)")
                    .font(.system(.body, design: .monospaced))
                sourceValue(
                    "Left",
                    value: entry.leftDescription,
                    line: entry.leftLine,
                    color: .red
                )
                sourceValue(
                    "Right",
                    value: entry.rightDescription,
                    line: entry.rightLine,
                    color: .green
                )
            }
        }
        .padding(.vertical, 2)
    }

    private func sourceValue(
        _ label: String,
        value: String?,
        line: Int?,
        color: Color
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(line.map { "\(label) · line \($0)" } ?? label)
                .font(.caption.bold())
            Text(value ?? "Not present")
                .font(.caption.monospaced())
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .foregroundStyle(value == nil ? .secondary : color)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(value == nil ? Color.secondary.opacity(0.08) : color.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
    }

    private var icon: some View {
        switch entry.kind {
        case .added:   return Image(systemName: "plus.circle.fill").foregroundStyle(Color.green)
        case .removed: return Image(systemName: "minus.circle.fill").foregroundStyle(Color.red)
        case .changed: return Image(systemName: "pencil.circle.fill").foregroundStyle(Color.orange)
        case .same:    return Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.secondary)
        }
    }
}
