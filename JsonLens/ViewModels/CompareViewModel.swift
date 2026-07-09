//
//  CompareViewModel.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import Foundation
internal import Combine


final class CompareViewModel: ObservableObject {

    func diffEntries(left: JSONEditorViewModel, right: JSONEditorViewModel) -> [DiffEntry]? {
        guard let l = left.parsedValue, let r = right.parsedValue else { return nil }
        return JSONDiffService.diff(left: l, right: r)
    }
}
