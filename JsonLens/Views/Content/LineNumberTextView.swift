//
//  LineNumberTextView.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import SwiftUI
import AppKit

/// A `NSRulerView` that draws 1-based line numbers next to an `NSTextView`.
/// This is the classic AppKit recipe for a code-editor gutter — SwiftUI's
/// `TextEditor` has no equivalent, which is why this whole file exists.
final class LineNumberRulerView: NSRulerView {

    weak var target: NSTextView?
    var errorLine: Int?   // 1-based line to highlight red (formatting-error tool)

    init(textView: NSTextView) {
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        self.target = textView
        self.clientView = textView
        self.ruleThickness = 44
    }

    required init(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = target,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        let content = textView.string as NSString
        let visibleRect = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        NSColor.textBackgroundColor.setFill()
        rect.fill()

        let font = textView.font ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: font.pointSize - 1, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let errorAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: font.pointSize - 1, weight: .bold),
            .foregroundColor: NSColor.systemRed
        ]

        var lineNumber = 1
        var index = 0
        // Count lines up to the start of the visible range.
        while index < charRange.location {
            let lineRange = content.lineRange(for: NSRange(location: index, length: 0))
            index = lineRange.location + lineRange.length
            if index <= charRange.location { lineNumber += 1 }
        }

        index = charRange.location
        while index <= charRange.location + charRange.length && index <= content.length {
            let lineRange = content.lineRange(for: NSRange(location: index, length: 0))
            let glyphIndexForLine = layoutManager.glyphIndexForCharacter(at: lineRange.location)
            var lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndexForLine, effectiveRange: nil)
            lineRect.origin.y += textView.textContainerInset.height

            let numberString = "\(lineNumber)" as NSString
            let isErrorLine = (lineNumber == errorLine)
            let size = numberString.size(withAttributes: isErrorLine ? errorAttrs : attrs)
            let y = lineRect.minY - visibleRect.minY
            let x = ruleThickness - size.width - 8
            numberString.draw(at: NSPoint(x: x, y: y), withAttributes: isErrorLine ? errorAttrs : attrs)

            if lineRange.location + lineRange.length >= content.length { break }
            index = lineRange.location + lineRange.length
            lineNumber += 1
        }
    }
}

/// SwiftUI wrapper exposing a plain-text, monospaced, line-numbered editor.
struct LineNumberTextView: NSViewRepresentable {

    @Binding var text: String
    var errorLine: Int? = nil
    var isEditable: Bool = true
    var fontSize: CGFloat = 12

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isEditable = isEditable
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.autoresizingMask = [.width]
        textView.string = text

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false

        let ruler = LineNumberRulerView(textView: textView)
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        context.coordinator.textView = textView
        context.coordinator.rulerView = ruler
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        if textView.string != text {
            textView.string = text
        }
        if textView.font?.pointSize != fontSize {
            textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
        context.coordinator.rulerView?.errorLine = errorLine
        context.coordinator.rulerView?.needsDisplay = true
        textView.isEditable = isEditable
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        weak var textView: NSTextView?
        weak var rulerView: LineNumberRulerView?

        init(text: Binding<String>) { self.text = text }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            let newValue = tv.string
            // Defer the @Published write to the next run loop turn. NSTextView calls this
            // delegate method synchronously while typing, which can land on the same cycle
            // as a SwiftUI view update already in progress — writing straight into the
            // binding here is what triggers "Publishing changes from within view updates".
            DispatchQueue.main.async { [weak self] in
                self?.text.wrappedValue = newValue
                self?.rulerView?.needsDisplay = true
            }
        }
    }
}
