//
//  AppViewModel.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import Foundation
internal import Combine
import SwiftData

/// Owns navigation state (selected tool) and the document(s) that state operates on.
final class AppViewModel: ObservableObject {
    @Published var selectedTool: Tool = .visualize

    /// Used by Visualize, Convert to Type, Format Checker, and the left Compare pane.
    @Published var document = JSONEditorViewModel()

    /// Used by the right Compare pane.
    @Published var compareRight = JSONEditorViewModel()

    @Published var selectedLanguage: OutputLanguage = .swift

    @Published var selectedSnippetID: PersistentIdentifier?

    private var cancellables = Set<AnyCancellable>()

    init() {
        document.objectWillChange
            .merge(with: compareRight.objectWillChange)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func loadIntoEditor(_ snippet: SavedSnippet) {
        document.text = snippet.jsonText
        selectedTool = .visualize
    }
}
