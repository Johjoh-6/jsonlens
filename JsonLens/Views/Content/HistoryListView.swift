//
//  HistoryListView.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import SwiftUI
import SwiftData

struct HistoryListView: View {
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedSnippet.createdAt, order: .reverse) private var snippets: [SavedSnippet]
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Saved Snippets").font(.headline)
                Spacer()
                Text("\(snippets.count)").foregroundStyle(.secondary).font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Divider()

            if snippets.isEmpty {
                ContentUnavailableView("No saved snippets yet", systemImage: "clock.arrow.circlepath",
                                        description: Text("Use the save button in any editor toolbar to keep a JSON snippet here."))
            } else {
                List(filtered, selection: $appViewModel.selectedSnippetID) { snippet in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(snippet.name).font(.body)
                        Text(snippet.createdAt, format: .dateTime.day().month().year().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(snippet.id)
                    .padding(.vertical, 2)
                }
                .searchable(text: $searchText, placement: .toolbar, prompt: "Search snippets")
                .listStyle(.inset)
            }
        }
    }

    private var filtered: [SavedSnippet] {
        guard !searchText.isEmpty else { return snippets }
        return snippets.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}
