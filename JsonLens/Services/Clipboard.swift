//
//  Clipboard.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import AppKit

enum Clipboard {
    static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
