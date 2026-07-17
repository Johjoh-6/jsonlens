//
//  CodeEditorCoordinator.swift
//  JsonLens
//
//  Created by Six Johann  on 09/07/2026.
//

import Foundation
import AppKit
internal import Combine
import SwiftUI

final class CodeEditorCoordinator: NSObject, NSTextViewDelegate {

    var text: Binding<String>
    let state: EditorState

    weak var textView: NSTextView?
    weak var ruler: LineNumberRulerView?

    init(text: Binding<String>, state: EditorState) {
        self.text = text
        self.state = state
    }

    func textDidChange(_ notification: Notification) {
        guard let tv = notification.object as? NSTextView else { return }
        DispatchQueue.main.async {
            self.text.wrappedValue = tv.string
        }
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard let tv = notification.object as? NSTextView else { return }
        let range = tv.selectedRange()
        state.selectedRange = range
        updateCursor(tv)
    }

    private func updateCursor(_ textView: NSTextView) {
        let position = textView.selectedRange().location
        let nsText = textView.string as NSString
        let before = nsText.substring(with: NSRange(location: 0, length: position))
        let lines = before.split(separator: "\n", omittingEmptySubsequences: false)

        state.cursorLine = lines.count
        state.cursorColumn = (lines.last?.count ?? 0) + 1
    }
}
