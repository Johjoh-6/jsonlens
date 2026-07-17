//
//  CompareViewModel.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import Foundation
internal import Combine


final class CompareViewModel: ObservableObject {

    func diffEntries(document: JSONEditorViewModel, comparison: JSONEditorViewModel) -> [DiffEntry]? {
        guard let documentValue = document.parsedValue,
              let comparisonValue = comparison.parsedValue
        else {
            return nil
        }

        let documentLines = JSONParser.lineNumbers(in: document.text)
        let comparisonLines = JSONParser.lineNumbers(in: comparison.text)

        return JSONDiffService.diff(left: documentValue, right: comparisonValue).map { entry in
            DiffEntry(
                path: entry.path,
                kind: entry.kind,
                leftDescription: entry.leftDescription,
                rightDescription: entry.rightDescription,
                leftLine: documentLines[entry.path],
                rightLine: comparisonLines[entry.path]
            )
        }
    }
}
