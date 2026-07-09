//
//  JSONEditorViewModel.swift
//  JsonLens
//
//  Created by Six Johann  on 15/06/2026.
//

import Foundation
internal import Combine

/// Wraps one pane of editable JSON text. Compare uses two instances of this;
/// every other tool shares one via `AppViewModel`.
final class JSONEditorViewModel: ObservableObject {
    @Published var text: String {
        didSet { reparse() }
    }
    @Published private(set) var parseResult: Result<JSONValue, JSONParseError>?

    init(text: String = "") {
        self.text = text
        reparse()
    }

    var lineCount: Int {
        guard !text.isEmpty else { return 1 }
        return text.reduce(1) { count, ch in ch == "\n" ? count + 1 : count }
    }

    var characterCount: Int { text.count }

    var parsedValue: JSONValue? {
        if case .success(let value) = parseResult { return value }
        return nil
    }

    var error: JSONParseError? {
        if case .failure(let err) = parseResult { return err }
        return nil
    }

    func loadSample() {
        text = """
        {
          "name": "Ada Lovelace",
          "born": 1815,
          "isProgrammer": true,
          "skills": ["mathematics", "analytical engines"],
          "address": {
            "city": "London",
            "country": "England"
          },
          "notes": null
        }
        """
    }

    func format() {
        guard let value = parsedValue else { return }
        text = JSONPrettyPrinter.print(value)
    }

    func minify() {
        guard let value = parsedValue else { return }
        text = JSONMinifier.minify(value)
    }

    var stats: JSONStats { JSONStats.compute(text: text, value: parsedValue) }

    private func reparse() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            parseResult = nil
            return
        }
        parseResult = JSONParser.parse(text)
    }
}
