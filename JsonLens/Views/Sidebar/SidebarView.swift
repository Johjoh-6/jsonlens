//
//  SidebarView.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var appViewModel: AppViewModel

    var body: some View {
        List(Tool.allCases, selection: $appViewModel.selectedTool) { tool in
            Label(tool.title, systemImage: tool.systemImage)
                .tag(tool)
        }
        .navigationTitle("JsonLens")
        .listStyle(.sidebar)
    }
}
