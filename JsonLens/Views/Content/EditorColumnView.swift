//
//  EditorColumnView.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import SwiftUI
import SwiftData

/// The middle "Content" column of the NavigationSplitView. Its layout adapts to the
/// selected tool: a single editor pane normally, two side-by-side panes for Compare,
/// or the saved-snippets list for History.
struct EditorColumnView: View {
    @ObservedObject var appViewModel: AppViewModel

    var body: some View {
        Group {
            switch appViewModel.selectedTool {
            case .history:
                HistoryListView(appViewModel: appViewModel)
            case .setting:
                SettingsFeatureView(appViewModel: appViewModel)
            case .compare:
                HSplitView {
                    JSONEditorPane(title: "Left JSON", viewModel: appViewModel.compareLeft)
                    JSONEditorPane(title: "Right JSON", viewModel: appViewModel.compareRight)
                }
            case .visualize, .generateType, .validate:
                JSONEditorPane(title: "JSON Input", viewModel: appViewModel.document)
            }
        }
        .navigationTitle(appViewModel.selectedTool.title)
    }
}

/// A single labeled editor pane: line-numbered text view, a toolbar (format / minify /
/// copy / save to history / info), and a compact status strip.
struct JSONEditorPane: View {
    let title: String
    @ObservedObject var viewModel: JSONEditorViewModel

    @Environment(\.modelContext) private var modelContext
    @AppStorage("editorFontSize") private var editorFontSize: Double = 12
    @State private var showingInfoPopover = false
    @State private var showingSaveAlert = false
    @State private var snippetName = ""
    @State private var showingCopyConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: 36)
                .background(.bar)
                .layoutPriority(1)
            Divider()
            LineNumberTextView(text: $viewModel.text, errorLine: viewModel.error?.line, fontSize: CGFloat(editorFontSize))
                .frame(minWidth: 320, minHeight: 120)
            Divider()
            statusBar
                .frame(height: 28)
                .background(.bar)
                .layoutPriority(1)
        }
        .alert("Save to History", isPresented: $showingSaveAlert) {
            TextField("Name", text: $snippetName)
            Button("Cancel", role: .cancel) {}
            Button("Save") { saveSnippet() }
        } message: {
            Text("This snippet will be available from the History tool.")
        }
    }

    // MARK: - Header / toolbar

    private var header: some View {
        HStack(spacing: 14) {
            Text(title)
                .font(.headline)

            Spacer()

            Button { viewModel.loadSample() } label: {
                Image(systemName: "wand.and.stars")
            }
            .help("Load sample JSON")

            Button { viewModel.format() } label: {
                Image(systemName: "list.bullet.indent")
            }
            .disabled(viewModel.parsedValue == nil)
            .help("Format (pretty-print)")

            Button { viewModel.minify() } label: {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
            }
            .disabled(viewModel.parsedValue == nil)
            .help("Minify (strip whitespace)")

            Button {
                Clipboard.copy(viewModel.text)
                showingCopyConfirmation = true
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .disabled(viewModel.text.isEmpty)
            .help("Copy to clipboard")
            .popover(isPresented: $showingCopyConfirmation, arrowEdge: .bottom) {
                Text("Copied")
                    .font(.caption)
                    .padding(8)
                    .background(.regularMaterial)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                            showingCopyConfirmation = false
                        }
                    }
            }

            Button {
                snippetName = defaultSnippetName()
                showingSaveAlert = true
            } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .disabled(viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help("Save to History")

            Button { showingInfoPopover = true } label: {
                Image(systemName: "info.circle")
            }
            .help("Document info")
            .popover(isPresented: $showingInfoPopover, arrowEdge: .bottom) {
                InfoPopoverContent(stats: viewModel.stats, isValid: viewModel.error == nil && viewModel.parsedValue != nil)
            }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Label("\(viewModel.lineCount) lines", systemImage: "list.number")
            Label("\(viewModel.characterCount) chars", systemImage: "textformat.size")
            Spacer()
            if let error = viewModel.error {
                Label("Line \(error.line), Col \(error.column)", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } else if viewModel.parsedValue != nil {
                Label("Valid JSON", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private func defaultSnippetName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "Snippet — \(formatter.string(from: .now))"
    }

    private func saveSnippet() {
        let name = snippetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let snippet = SavedSnippet(name: name.isEmpty ? defaultSnippetName() : name, jsonText: viewModel.text)
        modelContext.insert(snippet)
    }
}

private struct InfoPopoverContent: View {
    let stats: JSONStats
    let isValid: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(isValid ? "Valid JSON" : "Not valid JSON", systemImage: isValid ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundStyle(isValid ? .green : .red)
                .font(.headline)

            Divider()

            row("Lines", "\(stats.lines)")
            row("Characters", "\(stats.characters)")
            row("Bytes (UTF-8)", "\(stats.bytes)")
            if let depth = stats.maxDepth {
                row("Max nesting depth", "\(depth)")
            }
            if let count = stats.topLevelCount {
                row("Top-level entries", "\(count)")
            }
        }
        .padding(12)
        .frame(width: 220)
        .background(.regularMaterial)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(.body, design: .monospaced))
        }
        .font(.caption)
    }
}
