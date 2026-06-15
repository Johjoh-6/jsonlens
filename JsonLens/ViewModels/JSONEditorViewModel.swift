//
//  JSONEditorViewModel.swift
//  JsonLens
//
//  Created by Six Johann  on 15/06/2026.
//

import Foundation
import SwiftUI
internal import Combine


/// Manages JSON parsing and tree state
@MainActor
final class JSONEditorViewModel: ObservableObject {

    // MARK: - Published State

    /// Raw JSON entered by the user
    @Published var jsonString: String = "{}" {
        didSet {
            parseJSON()
        }
    }

    /// Parsed JSON tree
    @Published private(set) var jsonTree: [JSONNode] = []

    /// Whether the current JSON is valid
    @Published private(set) var isValidJSON: Bool = true

    /// Parsing error, if any
    @Published private(set) var errorMessage: String?

    /// Currently selected node
    @Published var selectedNode: JSONNode? = nil

    // MARK: - Initialization

    init() {
        parseJSON()
    }

    // MARK: - Parsing

    /// Parses the current JSON string into a tree structure
    func parseJSON() {

        let normalizedJSON = normalizeQuotes(in: jsonString)

        guard let data = normalizedJSON.data(using: .utf8) else {
            isValidJSON = false
            errorMessage = "Invalid UTF-8 encoding"
            jsonTree = []
            return
        }

        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)

            jsonTree = JSONParser.buildTree(from: jsonObject)
            isValidJSON = true
            errorMessage = nil

        } catch {
            isValidJSON = false
            errorMessage = error.localizedDescription
            jsonTree = []
        }
    }

    // MARK: - Formatting

    /// Pretty prints the current JSON if valid
    func formatJSON() {

        let normalizedJSON = normalizeQuotes(in: jsonString)

        guard let data = normalizedJSON.data(using: .utf8) else {
            print("Format failed: Invalid UTF-8")
            return
        }

        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)

            let formattedData = try JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.prettyPrinted]
            )

            guard let formattedString = String(
                data: formattedData,
                encoding: .utf8
            ) else {
                print("Format failed: Could not create string")
                return
            }

            
            jsonString = formattedString
            

        } catch {
            print("Format failed: \(error.localizedDescription)")
            errorMessage = "Cannot format: \(error.localizedDescription)"
        }
    }

    // MARK: - Tree Navigation

    /// Finds a node using its path
    func findNode(byPath path: String) -> JSONNode? {

        var stack = jsonTree

        while let node = stack.popLast() {

            if node.path == path {
                return node
            }

            if let children = node.children {
                stack.append(contentsOf: children)
            }
        }

        return nil
    }

    // MARK: - Helpers

    /// Replaces smart quotes with standard quotes for JSON parsing.
    private func normalizeQuotes(in text: String) -> String {
        text
            .replacingOccurrences(of: "\u{201C}", with: "\"") // “
            .replacingOccurrences(of: "\u{201D}", with: "\"") // ”
            .replacingOccurrences(of: "\u{2018}", with: "'")  // ‘
            .replacingOccurrences(of: "\u{2019}", with: "'")  // ’
    }
}
