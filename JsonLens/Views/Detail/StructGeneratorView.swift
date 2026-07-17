//
//  StructGeneratorView.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import SwiftUI
import Foundation

struct StructGeneratorView: View {
    @ObservedObject var document: JSONEditorViewModel
    @Binding var selectedLanguage: OutputLanguage
    @StateObject private var viewModel = StructGeneratorViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Convert to Type").font(.title2.bold())
                Spacer()
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(OutputLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)
            }
            .padding([.top, .horizontal])

            HStack {
                Text("Root type name")
                TextField("Root", text: $viewModel.rootTypeName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)
                Spacer()
                Button {
                    Clipboard.copy(generatedCode)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .disabled(document.parsedValue == nil)
                .accessibilityIdentifier("structGenerator.copyButton")
            }
            .padding(.horizontal)

            Divider()

            if document.parsedValue != nil {
                ScrollView {
                    Text(highlightedCode)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            } else if let error = document.error {
                ContentUnavailableView(
                    "Can't generate types from invalid JSON",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Line \(error.line), column \(error.column): \(error.message)")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("structGenerator.invalidState")
            } else {
                ContentUnavailableView(
                    "Paste JSON in the editor",
                    systemImage: "doc.badge.plus",
                    description: Text("Generated types will appear here.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("structGenerator.emptyState")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var generatedCode: String {
        viewModel.generatedCode(for: document.parsedValue, language: selectedLanguage)
    }

    private var highlightedCode: AttributedString {
        GeneratedCodeHighlighter.highlight(generatedCode, language: selectedLanguage)
    }
}

private enum GeneratedCodeHighlighter {
    static func highlight(_ code: String, language: OutputLanguage) -> AttributedString {
        var result = AttributedString(code)

        apply("\\b[A-Z][A-Za-z0-9_]*\\b", color: .teal, to: &result, source: code)
        apply("\\b[A-Za-z_][A-Za-z0-9_]*(?=\\s*:)", color: .blue, to: &result, source: code)
        apply("\\b\\d+(?:\\.\\d+)?\\b", color: .purple, to: &result, source: code)
        apply("\\b(?:\(language.generatedCodeKeywords.joined(separator: "|")))\\b", color: .pink, to: &result, source: code)
        apply("\\\"(?:[^\\\"\\\\]|\\\\.)*\\\"", color: .orange, to: &result, source: code)
        apply("(?://.*$|#.*$)", color: .secondary, to: &result, source: code, options: [.anchorsMatchLines])

        return result
    }



    private static func apply(
        _ pattern: String,
        color: Color,
        to attributed: inout AttributedString,
        source: String,
        options: NSRegularExpression.Options = []
    ) {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: options) else {
            return
        }

        let sourceRange = NSRange(source.startIndex..., in: source)
        for match in expression.matches(in: source, range: sourceRange) {
            guard let stringRange = Range(match.range, in: source),
                  let attributedRange = Range(stringRange, in: attributed)
            else {
                continue
            }
            attributed[attributedRange].foregroundColor = color
        }
    }
}
