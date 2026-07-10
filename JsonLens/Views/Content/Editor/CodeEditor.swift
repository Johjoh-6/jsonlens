//
//  CodeEditor.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import SwiftUI
import AppKit

struct CodeEditor: NSViewRepresentable {

    @Binding var text: String
    let state: EditorState
    var errorLine: Int?
    var fontSize: CGFloat = 12

    func makeCoordinator() -> CodeEditorCoordinator {
        CodeEditorCoordinator(
            text: $text,
            state: state
        )
    }

    func makeNSView(context: Context) -> NSScrollView {

        // Must call scrollableTextView() on the *subclass*, not on NSTextView itself —
        // otherwise it always constructs a plain NSTextView and the cast below always
        // fails, silently skipping every bit of setup after the guard.
        let scrollView = CodeTextView.scrollableTextView()

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        guard let textView = scrollView.documentView as? CodeTextView else {
            return scrollView
        }

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false

        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 8, height: 8)

        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.textColor = .labelColor
        textView.insertionPointColor = .labelColor

        textView.string = text

        state.textView = textView
        // This was the second bug: without this line, `updateNSView` below always
        // early-returns because context.coordinator.textView stays nil forever.
        context.coordinator.textView = textView

        let ruler = LineNumberRulerView(textView: textView)
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        context.coordinator.ruler = ruler

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }

        if textView.string != text {
            let previousSelection = textView.selectedRange()
            // Silence the delegate for our own programmatic write — NSTextView's
            // `.string` setter goes through the text storage and does post change
            // notifications, so without this we'd re-enter textDidChange (and
            // re-publish `text`) from inside this very view update.
            textView.delegate = nil
            textView.string = text
            textView.delegate = context.coordinator

            // Format/Minify change the text length, so the old selection may no
            // longer be valid — clamp it instead of risking an out-of-range crash.
            let length = (textView.string as NSString).length
            let location = min(previousSelection.location, length)
            let rangeLength = min(previousSelection.length, length - location)
            textView.setSelectedRange(NSRange(location: location, length: rangeLength))
        }

        if textView.font?.pointSize != fontSize {
            textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }

        context.coordinator.ruler?.errorLine = errorLine
        context.coordinator.ruler?.needsDisplay = true
    }
}
