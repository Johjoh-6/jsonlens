//
//  ValidatorView.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import SwiftUI

struct ValidatorView: View {
    @ObservedObject var document: JSONEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Format Checker").font(.title2.bold())

            if document.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView("Paste JSON in the editor", systemImage: "checkmark.seal")
            } else if let error = document.error {
                invalidCard(error)
            } else {
                validCard
            }

            Spacer()
        }
        .padding()
    }

    private var validCard: some View {
        GroupBox {
            Label("Valid JSON", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.headline)
            Text("\(document.lineCount) lines · \(document.characterCount) characters")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 2)
    }

    private func invalidCard(_ error: JSONParseError) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Label("Invalid JSON", systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
                    .font(.headline)

                Text(error.message)
                    .font(.body)

                HStack(spacing: 16) {
                    Label("Line \(error.line)", systemImage: "arrow.turn.down.right")
                    Label("Column \(error.column)", systemImage: "arrow.right.to.line")
                }
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.secondary)

                Divider()

                Text("Offending line")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(offendingLineSnippet(error))
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 2)
    }

    /// Pulls the exact source line the error occurred on, with a caret under the column.
    private func offendingLineSnippet(_ error: JSONParseError) -> String {
        let lines = document.text.components(separatedBy: "\n")
        guard error.line - 1 >= 0, error.line - 1 < lines.count else { return "" }
        let line = lines[error.line - 1]
        let caretIndex = max(0, min(error.column - 1, line.count))
        let caretLine = String(repeating: " ", count: caretIndex) + "^"
        return line + "\n" + caretLine
    }
}

