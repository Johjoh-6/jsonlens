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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedSnippet.createdAt, order: .reverse) private var snippets: [SavedSnippet]



    @State private var showingInfoPopover = false
    @State private var showingSaveAlert = false
    @State private var snippetName = ""
    @State private var showingCopyConfirmation = false
    @State private var showingLoadAlert = false
    @State private var showingLoadFrom = ""

    var body: some View {
        Group {
            switch appViewModel.selectedTool {
            case .history:
                HistoryListView(appViewModel: appViewModel)
            case .setting:
                SettingsFeatureView(appViewModel: appViewModel)
            case .compare:
                HSplitView {
                    JSONEditorPane(label: "Left", viewModel: appViewModel.document, minimumWidth: 160)
                    JSONEditorPane(label: "Right", viewModel: appViewModel.compareRight, minimumWidth: 160)
                }
            case .visualize, .generateType, .validate, .extract:
                JSONEditorPane(label: nil, viewModel: appViewModel.document)
            }
        }
        .navigationTitle(appViewModel.selectedTool.title)
        .toolbar { toolbarContent }
        .alert("Save to History", isPresented: $showingSaveAlert) {
            TextField("Name", text: $snippetName)
            Button("Cancel", role: .cancel) {}
            Button("Save") { saveSnippet() }
        } message: {
            Text("This snippet will be available from the History tool.")
        }
    }

    /// The shared app document is the target for all toolbar actions, including
    /// Compare mode where it appears in the left pane.
    private var activeDocument: JSONEditorViewModel {
        appViewModel.document
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if appViewModel.selectedTool.usesEditorPane {

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    loadSnippet()
                    showingLoadAlert = true
                } label: {
                    Image(systemName: "wand.and.stars")
                }
                .help("Load last JSON")
                .popover(isPresented: $showingLoadAlert, arrowEdge: .bottom) {
                    Text("Loaded from \(showingLoadFrom)")
                        .font(.caption)
                        .padding(8)
                        .background(.regularMaterial)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                showingLoadAlert = false
                            }
                        }
                }
                Button {
                    snippetName = defaultSnippetName()
                    showingSaveAlert = true
                } label: {
                    Image(systemName: "tray.and.arrow.down")
                }
                .disabled(activeDocument.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .help("Save to History")
                .keyboardShortcut("S", modifiers: [.command])
                
                Button {
                    activeDocument.text = ""
                } label : {
                    Image(systemName: "delete.left")
                }
                .disabled(activeDocument.parsedValue == nil)
                .help("Clear the editor")
                
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    activeDocument.format()
                } label: {
                    Image(systemName: "list.bullet.indent")
                }
                .disabled(activeDocument.parsedValue == nil)
                .help("Format (pretty-print)")
                .keyboardShortcut("F", modifiers: [.command])
                
                Button {
                    activeDocument.minify()
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                }
                .disabled(activeDocument.parsedValue == nil)
                .help("Minify (strip whitespace)")
                .keyboardShortcut("M", modifiers: [.command])

                Button {
                    Clipboard.copy(activeDocument.text)
                    showingCopyConfirmation = true
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .disabled(activeDocument.text.isEmpty)
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
                    showingInfoPopover.toggle()
                } label: {
                    Image(systemName: "info.circle")
                }
                .help("Document info")
                .keyboardShortcut("I", modifiers: [.command])
                .popover(isPresented: $showingInfoPopover, arrowEdge: .bottom) {
                    InfoPopoverContent(
                        stats: activeDocument.stats,
                        isValid: activeDocument.error == nil && activeDocument.parsedValue != nil
                    )
                }
            }
        }
    }
    
    private func loadSnippet(){
        guard let snippet = snippets.first else {
            activeDocument.loadSample()
            showingLoadFrom = "Sample"
            return
        }
        activeDocument.text = snippet.jsonText
        showingLoadFrom = "Last History"
    }

    private func defaultSnippetName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "Snippet — \(formatter.string(from: .now))"
    }

    private func saveSnippet() {
        let name = snippetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let snippet = SavedSnippet(name: name.isEmpty ? defaultSnippetName() : name, jsonText: activeDocument.text)
        modelContext.insert(snippet)
    }
}

/// A single editor pane: the code editor plus a compact status strip below it.
/// `label` is only used in Compare mode to distinguish the two panes.
struct JSONEditorPane: View {
    let label: String?
    @ObservedObject var viewModel: JSONEditorViewModel
    let minimumWidth: CGFloat

    init(label: String?, viewModel: JSONEditorViewModel, minimumWidth: CGFloat = 320) {
        self.label = label
        self.viewModel = viewModel
        self.minimumWidth = minimumWidth
    }
    @AppStorage("editorFontSize") private var editorFontSize: Double = 12

    var body: some View {
        VStack(spacing: 0) {
            if let label {
                HStack {
                    Text(label)
                        .font(.caption.bold())
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.regularMaterial)
            }

            CodeEditor(
                text: $viewModel.text,
                state: viewModel.editorState,
                errorLine: viewModel.error?.line,
                fontSize: CGFloat(editorFontSize)
            )
            .frame(minWidth: minimumWidth, minHeight: 120)

            Divider()
            statusBar
                .frame(height: 28)
                .background(.regularMaterial)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Label("\(viewModel.lineCount) lines", systemImage: "list.number")
            Label("\(viewModel.characterCount) chars", systemImage: "textformat.size")
            Label("Ln \(viewModel.editorState.cursorLine), Col \(viewModel.editorState.cursorColumn)", systemImage: "cursorarrow")
                .foregroundStyle(.secondary)
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
