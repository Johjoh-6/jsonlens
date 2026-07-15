//
//  ContentView.swift
//  JsonLens
//
//  Created by Six Johann  on 15/06/2026.
//

import SwiftUI


struct ContentView: View {
    //    Manage the navigation between page
    @StateObject private var appViewModel = AppViewModel()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(appViewModel: appViewModel)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } content: {
            EditorColumnView(appViewModel: appViewModel)
                .navigationSplitViewColumnWidth(min: 340, ideal: 460)
        } detail: {
            DetailContainerView(appViewModel: appViewModel)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    ContentView()
        .frame(width: 1100, height: 700)
}

