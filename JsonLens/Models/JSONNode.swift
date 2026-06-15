//
//  JSONNode.swift
//  JsonLens
//
//  Created by Six Johann on 15/06/2026.
//

import Foundation

/// A single node in the JSON tree structure
struct JSONNode: Identifiable, Hashable {
    let id = UUID()
    
    let path: String          // e.g., "root.user.name" or "root.items[0]"
    let value: Any            // The actual JSON value
    let type: JSONType        // The type of this value
    let children: [JSONNode]? // Child nodes (nil for leaf nodes)
    
    init(path: String, value: Any, type: JSONType, children: [JSONNode]? = nil) {
        self.path = path
        self.value = value
        self.type = type
        self.children = children
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Hash only by id for avoir recursion !
    }
    
    static func == (lhs: JSONNode, rhs: JSONNode) -> Bool {
        lhs.id == rhs.id
    }
}
