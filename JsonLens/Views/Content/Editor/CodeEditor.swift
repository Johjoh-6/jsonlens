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

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        // macOS 14+ defaults clipsToBounds to false; keep the scroll view clipping
        // so the ruler can't bleed past it (e.g. up into the title bar).
        scrollView.clipsToBounds = true

        // Build ONE clean TextKit stack owned directly by CodeTextView. The old
        // approach let scrollableTextView() build a stack and then re-hosted its
        // NSTextContainer inside a second (our) text view — leaving the layout
        // manager half-wired to two views. Glyphs then only flushed to the visible
        // view after a forced re-layout (typing / scroll / SwiftUI update), which
        // is exactly the "present but not drawn until it updates" symptom.
        //
        // The sizing flags below are the ones whose absence makes a hand-rolled
        // NSTextView look "dead" (zero-width container → no layout → clicks miss):
        //   • container.widthTracksTextView + height .greatestFiniteMagnitude
        //   • isVerticallyResizable = true
        //   • autoresizingMask = [.width]  (so it tracks the clip view width)
        let contentSize = scrollView.contentSize

        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(
            size: NSSize(width: contentSize.width, height: .greatestFiniteMagnitude)
        )
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        let textView = CodeTextView(
            frame: NSRect(origin: .zero, size: contentSize),
            textContainer: textContainer
        )
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

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
        // All three must be dynamic system colors so they track light/dark mode
        // together. Hardcoding `.black` here made the text and caret invisible in
        // Dark Mode, since `.textBackgroundColor` flips to near-black — the content
        // was present and editable (Cmd-Z, selection all worked), just unpainted.
        textView.backgroundColor = .textBackgroundColor
        textView.textColor = .textColor
        textView.insertionPointColor = .textColor

        textView.string = text

        scrollView.documentView = textView

        state.textView = textView
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
