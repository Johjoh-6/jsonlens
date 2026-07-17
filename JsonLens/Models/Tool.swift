//
//  Tool.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import Foundation
import SwiftUI

/// The tools available in the sidebar. Each maps to a Detail view.
enum Tool: String, CaseIterable, Identifiable, Hashable {
    case visualize
    case generateType
    case compare
    case validate
    case history
    case setting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .visualize:    return "Visualize"
        case .generateType: return "Convert to Type"
        case .compare:      return "Compare JSON"
        case .validate:     return "Format Checker"
        case .history:      return "History"
        case .setting:      return "Setting"
        }
    }

    var systemImage: String {
        switch self {
        case .visualize:    return "chart.bar.doc.horizontal"
        case .generateType: return "curlybraces"
        case .compare:      return "arrow.left.arrow.right.square"
        case .validate:     return "checkmark.seal"
        case .history:      return "clock.arrow.circlepath"
        case .setting:      return "gearshape"
        }
    }

    /// Compare needs two JSON documents side by side instead of the single shared editor.
    var needsTwoDocuments: Bool { self == .compare }

    /// History and Setting doesn't edit JSON directly — its Content column is a browsable list instead.
    var usesEditorPane: Bool { self != .history && self != .setting }
}
