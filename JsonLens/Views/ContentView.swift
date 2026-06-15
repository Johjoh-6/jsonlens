//
//  ContentView.swift
//  JsonLens
//
//  Created by Six Johann  on 15/06/2026.
//

import SwiftUI

/// Main view combining editor and tree visualization
/// This is a View: coordinates sub-views, handles user input
struct ContentView: View {
    
    // MARK: - ViewModel (Owned by this View)
    @StateObject private var viewModel = JSONEditorViewModel()
    
    // MARK: - Body
    var body: some View {
        NavigationSplitView {
            // Sidebar: JSON Tree
            JSONTreeView(viewModel: viewModel)
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        } detail: {
            // Main area: JSON Editor
            VStack(spacing: 0) {
                // JSON Text Editor
                TextEditor(text: $viewModel.jsonString)
                    .font(.system(size: 16, weight: .light, design: .default))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.isValidJSON ? Color.green : Color.red, lineWidth: 2)
                    )
                    .padding(4)
                    .background(Color(.textBackgroundColor))
                
                // Status bar
                HStack {
                    if viewModel.isValidJSON {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Valid JSON")
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text(viewModel.errorMessage ?? "Invalid JSON")
                    }
                    
                    Spacer()
                    
                    // Node count
                    Text("\(viewModel.jsonTree.count) root nodes")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Format") {
                        viewModel.formatJSON()
                    }
                }
                .padding(4)
                .background(Color(.windowBackgroundColor))
            }.padding(4)
            .navigationTitle("JsonLens")
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

#Preview {
    ContentView()
}
