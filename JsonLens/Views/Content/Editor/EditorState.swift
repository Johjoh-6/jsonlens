//
//  EditorState.swift
//  JsonLens
//
//  Created by Six Johann  on 09/07/2026.
//

import Foundation
import AppKit
internal import Combine


@MainActor
final class EditorState: ObservableObject {

    @Published var cursorLine: Int = 1
    @Published var cursorColumn: Int = 1

    @Published var selectedRange =
        NSRange(location: 0, length: 0)

    @Published var hasFocus = false


    weak var textView: NSTextView?


    func focus() {
        guard let textView else { return }
        textView.window?.makeFirstResponder(textView)
    }


    func scrollTo(range: NSRange) {
        textView?.scrollRangeToVisible(range)
        textView?.setSelectedRange(range)
    }
}
