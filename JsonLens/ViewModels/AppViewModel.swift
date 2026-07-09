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

    /// Used by Visualize, Convert to Type, and Format Checker.
    @Published var document = JSONEditorViewModel()

    /// Used only by Compare.
    @Published var compareLeft = JSONEditorViewModel()
    @Published var compareRight = JSONEditorViewModel()

    @Published var selectedLanguage: OutputLanguage = .swift

    @Published var selectedSnippetID: PersistentIdentifier?

    func loadIntoEditor(_ snippet: SavedSnippet) {
        document.text = snippet.jsonText
        selectedTool = .visualize
    }
}
