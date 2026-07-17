//
//  HistoryDetailView.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import SwiftUI
import SwiftData

struct HistoryDetailView: View {
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var allSnippets: [SavedSnippet]
    @State private var editedName = ""
    @State private var showingDeleteConfirmation = false

    private var snippet: SavedSnippet? {
        guard let id = appViewModel.selectedSnippetID else { return nil }
        return allSnippets.first { $0.id == id }
    }

    var body: some View {
        Group {
            if let snippet {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField("Name", text: Binding(
                            get: { editedName.isEmpty ? snippet.name : editedName },
                            set: { editedName = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.title3.bold())
                        .onSubmit { commitRename(snippet) }
                        .onChange(of: snippet.id) { _, _ in editedName = "" }

                        Spacer()

                        Button {
                            appViewModel.loadIntoEditor(snippet)
                        } label: {
                            Label("Load into Editor", systemImage: "square.and.arrow.down.on.square")
                        }

                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    Text(snippet.createdAt, format: .dateTime.day().month().year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    ScrollView {
                        Text(snippet.jsonText)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .confirmationDialog("Delete this snippet?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) { delete(snippet) }
                    Button("Cancel", role: .cancel) {}
                }
            } else {
                ContentUnavailableView("Select a snippet", systemImage: "doc.text.magnifyingglass",
                                        description: Text("Choose a saved snippet from the list to preview it here."))
            }
        }
    }

    private func commitRename(_ snippet: SavedSnippet) {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        snippet.name = trimmed
        editedName = ""
    }

    private func delete(_ snippet: SavedSnippet) {
        appViewModel.selectedSnippetID = nil
        modelContext.delete(snippet)
    }
}
