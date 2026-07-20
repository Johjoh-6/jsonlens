//
//  JSONEditorViewModel.swift
//  JsonLens
//
//  Created by Six Johann  on 15/06/2026.
//

import Foundation
internal import Combine
import AppKit

/// Wraps one JSON editing document.
/// Used by Visualize, Validate, Generate and both sides of Compare.
@MainActor
final class JSONEditorViewModel: ObservableObject {

    @Published var text: String {
        didSet {
            reparse()
        }
    }

    @Published private(set) var parseResult:
        Result<JSONValue, JSONParseError>?

    /// State owned by the editor, not JSON.
    let editorState = EditorState()

    init(text: String = "") {
        self.text = text
        reparse()
    }


    // MARK: - JSON state

    var parsedValue: JSONValue? {
        if case .success(let value) = parseResult {
            return value
        }
        return nil
    }


    var error: JSONParseError? {
        if case .failure(let error) = parseResult {
            return error
        }
        return nil
    }


    // MARK: - Statistics

    var lineCount: Int {
        guard !text.isEmpty else {
            return 1
        }

        return text.reduce(1) {
            $1 == "\n" ? $0 + 1 : $0
        }
    }


    var characterCount: Int {
        text.count
    }


    var stats: JSONStats {
        JSONStats.compute(
            text: text,
            value: parsedValue
        )
    }


    // MARK: - Actions


    func loadSample() {

        text = """
        {
          "name": "Ada Lovelace",
          "born": 1815,
          "isProgrammer": true,
          "skills": [
            "mathematics",
            "analytical engines"
          ],
          "address": {
            "city": "London",
            "country": "England"
          },
          "notes": null
        }
        """
    }


    func format() {

        guard let value = parsedValue else {
            return
        }

        replaceTextPreservingCursor {
            JSONPrettyPrinter.print(value)
        }
    }


    func minify() {

        guard let value = parsedValue else {
            return
        }

        replaceTextPreservingCursor {
            JSONMinifier.minify(value)
        }
    }



    // MARK: - Private


    private func replaceTextPreservingCursor(
        _ generator: () -> String
    ) {

        let oldSelection = editorState.selectedRange

        text = generator()

        DispatchQueue.main.async {
            self.editorState.selectedRange = oldSelection
        }
    }


    private func reparse() {

        guard !text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        else {
            parseResult = nil
            return
        }

        parseResult = JSONParser.parse(text)
    }
    
    static var preview: JSONEditorViewModel {
        let vm = JSONEditorViewModel()
        vm.text = """
        {
            "users": [
                { "id": 1, "name": "Alice", "email": "alice@example.com" },
                { "id": 2, "name": "Bob", "email": "bob@example.com" }
            ]
        }
        """
        return vm
    }
}
