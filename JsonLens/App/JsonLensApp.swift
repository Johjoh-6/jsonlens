//
//  JsonLensApp.swift
//  JsonLens
//
//  Created by Six Johann on 10/06/2026.
//

import SwiftUI
import SwiftData

@main
struct JsonLensApp: App {
    var sharedModelContainer: ModelContainer = {
           let schema = Schema([
               SavedSnippet.self,
           ])
           let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

           do {
               return try ModelContainer(for: schema, configurations: [modelConfiguration])
           } catch {
               fatalError("Could not create ModelContainer: \(error)")
           }
       }()
    
    var body: some Scene {
        WindowGroup {
                    ContentView()
                        .frame(minWidth: 900, minHeight: 600)
                }
                .windowStyle(.automatic)
                .commands {
                    SidebarCommands()
                }
                .modelContainer(sharedModelContainer)
    }
}
