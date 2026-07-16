//
//  CompareView.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import SwiftUI

struct CompareView: View {
    @ObservedObject var left: JSONEditorViewModel
    @ObservedObject var right: JSONEditorViewModel
    @StateObject private var viewModel = CompareViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let leftError = left.error {
                statusBanner(title: "Left JSON is invalid", error: leftError)
            } else if let rightError = right.error {
                statusBanner(title: "Right JSON is invalid", error: rightError)
            } else if let entries = viewModel.diffEntries(left: left, right: right) {
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
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.path)
                    .font(.system(.body, design: .monospaced))
                if let l = entry.leftDescription {
                    Text("− \(l)").font(.caption.monospaced()).foregroundStyle(.red)
                }
                if let r = entry.rightDescription {
                    Text("+ \(r)").font(.caption.monospaced()).foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 2)
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
