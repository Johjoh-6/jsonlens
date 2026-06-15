//
//  JSONTreeNodeView.swift
//  JsonLens
//
//  Created by Six Johann  on 15/06/2026.
//

import SwiftUI

/// Displays a single JSON node with icon, name, and value preview
struct JSONTreeNodeView: View {
    
    // MARK: - Data (passed from parent)
    let node: JSONNode
    @Binding var selectedNode: JSONNode?
    
    // MARK: - Body
    var body: some View {
           VStack(alignment: .leading, spacing: 0) {
               // Node row
               HStack(alignment: .center, spacing: 8) {
                   typeIcon
                       .foregroundColor(typeColor)
                       .frame(width: 20)

                   Text(nodeName)
                       .frame(maxWidth: .infinity, alignment: .leading)

                   if node.children == nil {
                       Text(valuePreview)
                           .foregroundColor(.secondary)
                           .font(.system(.caption, design: .monospaced))
                           .lineLimit(1)
                   }
               }
               .padding(.vertical, 4)
               .background(
                   selectedNode == node ?
                   Color.accentColor.opacity(0.1) :
                   Color.clear
               )
               .onTapGesture {
                   selectedNode = node
               }
               .contextMenu {
                   Button("Copy Path") {
                       copyToPasteboard(string: node.path)
                   }
                   Button("Copy Value") {
                       copyToPasteboard(string: "\(node.value)")
                   }
               }

               // Recursive children
               if let children = node.children {
                   ForEach(children) { child in
                       JSONTreeNodeView(
                           node: child,
                           selectedNode: $selectedNode
                       )
                       .padding(.leading, 16)
                   }
               }
           }
       }
    
    // MARK: - Computed Properties
    
    private var nodeName: String {
        // Extract last component: "root.user.name" -> "name"
        node.path.components(separatedBy: CharacterSet(charactersIn: ".[]")).last ?? node.path
    }
    
    private var valuePreview: String {
        let stringValue = "\(node.value)"
        // Truncate long values
        if stringValue.count > 40 {
            return String(stringValue.prefix(37)) + "..."
        }
        return stringValue
    }
    
    // MARK: - Style for icons and colors
    private var typeIcon: some View {
        Group {
            switch node.type {
            case .object:  Image(systemName: "folder.fill")
            case .array:   Image(systemName: "list.bullet.rectangle.fill")
            case .string:  Image(systemName: "text.quote")
            case .number:  Image(systemName: "number")
            case .bool:    Image(systemName: "checkmark.square.fill")
            case .null:    Image(systemName: "xmark.square.fill")
            }
        }
    }
    
    private var typeColor: Color {
        switch node.type {
        case .object:  return .blue
        case .array:   return .purple
        case .string:  return .green
        case .number:  return .orange
        case .bool:    return .teal
        case .null:    return .gray
        }
    }
    
    // MARK: - Helper Methods
    
    private func copyToPasteboard(string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}


#Preview {
    @Previewable @State var selectedNode: JSONNode? = JSONNode(
        path: "root.user.name",
        value: "John Doe",
        type: .string
    )
    
    let sampleNode = JSONNode(
        path: "root.user.name",
        value: "John Doe",
        type: .string
    )

    JSONTreeNodeView(node: sampleNode, selectedNode: $selectedNode)
        .padding()
}
