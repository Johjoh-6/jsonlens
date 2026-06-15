//
//  JSONTreeView.swift
//  JsonLens
//
//  Created by Six Johann  on 15/06/2026.
//

import SwiftUI

/// Displays the JSON tree structure in a list
struct JSONTreeView: View {
    
    // MARK: - ViewModel (Observed)
    @ObservedObject var viewModel: JSONEditorViewModel
    
    // MARK: - Body
    var body: some View {
        List{
            ForEach(viewModel.jsonTree){ node in
                JSONTreeNodeView(
                    node: node,
                    selectedNode: $viewModel.selectedNode)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("JSON Structure")
        .overlay(
            // Show message when JSON is invalid
            Group {
                if !viewModel.isValidJSON {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                        Text("Invalid JSON")
                            .font(.headline)
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        )
    }
}

#Preview {
    let viewModel = JSONEditorViewModel()
    viewModel.jsonString = #"""
    {
        "user":{
            "name": "John",
            "age": 30,
            "isActive": true
        }
    }
    """#
    return JSONTreeView(viewModel: viewModel)
        .frame(width: 300)
}
