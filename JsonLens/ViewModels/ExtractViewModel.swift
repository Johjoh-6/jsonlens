//
//  ExtractViewModel.swift
//  JsonLens
//

import Foundation
internal import Combine

final class ExtractViewModel: ObservableObject {
    @Published private(set) var sources: [ExtractSource] = []
    @Published var selectedSourcePath: String?
    @Published var selectedFields: Set<String> = []
    @Published var separator: ExtractSeparator = .comma

    var selectedSource: ExtractSource? {
        sources.first { $0.path == selectedSourcePath }
    }

    var csvPreview: String {
        guard let selectedSource else { return "" }
        return ExtractService.delimitedText(
            source: selectedSource,
            fields: selectedFields,
            separator: separator
        )
    }

    func update(for value: JSONValue?) {
        let previousPath = selectedSourcePath
        if let value {
            sources = ExtractService.sources(in: value)
        } else {
            sources = []
        }

        guard let source = sources.first(where: { $0.path == previousPath }) ?? sources.first else {
            selectedSourcePath = nil
            selectedFields = []
            return
        }

        selectSource(source)
    }

    func selectSource(_ source: ExtractSource) {
        selectedSourcePath = source.path
        selectedFields = Set(source.fieldNames)
    }

    func setField(_ field: String, isSelected: Bool) {
        if isSelected {
            selectedFields.insert(field)
        } else {
            selectedFields.remove(field)
        }
    }
}
