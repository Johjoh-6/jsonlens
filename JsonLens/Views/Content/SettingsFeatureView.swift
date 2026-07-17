//
//  SettingsFeatureView.swift
//  JsonLens
//
//  Created by Six Johann  on 07/07/2026.
//

import SwiftUI
import SwiftData

/// Content-column view for the Settings tool: app-wide parameters plus destructive
/// "cleaning" actions (clear history, reset open editors). Preferences are stored
/// with @AppStorage so they persist across launches without needing SwiftData.
struct SettingsFeatureView: View {
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var snippets: [SavedSnippet]

    @AppStorage("editorFontSize") private var editorFontSize: Double = 12
    @AppStorage("defaultOutputLanguage") private var defaultOutputLanguageRaw: String = OutputLanguage.swift.rawValue

    @State private var showingClearHistoryConfirmation = false
    @State private var showingResetEditorsConfirmation = false

    var body: some View {
        Form {
            Section("Editor") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Font size")
                        Spacer()
                        Text("\(Int(editorFontSize)) pt").foregroundStyle(.secondary)
                    }
                    Slider(value: $editorFontSize, in: 10...20, step: 1)
                }
            }

            Section("Convert to Type") {
                Picker("Default language", selection: defaultLanguageBinding) {
                    ForEach(OutputLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                Text("Applied the next time you open the app. Changing the language while it's already open only affects the current session.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Data") {
                LabeledContent("Saved snippets", value: "\(snippets.count)")

                Button(role: .destructive) {
                    showingClearHistoryConfirmation = true
                } label: {
                    Label("Clear All History", systemImage: "trash")
                }
                .disabled(snippets.isEmpty)

                Button(role: .destructive) {
                    showingResetEditorsConfirmation = true
                } label: {
                    Label("Reset Open Editors", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .formStyle(.grouped)
        .confirmationDialog("Delete all \(snippets.count) saved snippets? This can't be undone.",
                             isPresented: $showingClearHistoryConfirmation, titleVisibility: .visible) {
            Button("Delete All", role: .destructive) { clearHistory() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Clear the text in every open editor (Visualize/Convert/Format and both Compare panes)?",
                             isPresented: $showingResetEditorsConfirmation, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { resetEditors() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var defaultLanguageBinding: Binding<OutputLanguage> {
        Binding(
            get: { OutputLanguage(rawValue: defaultOutputLanguageRaw) ?? .swift },
            set: { defaultOutputLanguageRaw = $0.rawValue }
        )
    }

    private func clearHistory() {
        for snippet in snippets { modelContext.delete(snippet) }
    }

    private func resetEditors() {
        appViewModel.document.text = ""
        appViewModel.compareRight.text = ""
    }
}

/// Small at-a-glance panel for the Detail column while Settings is selected.
struct SettingsSummaryView: View {
    @Query private var snippets: [SavedSnippet]

    var body: some View {
        ContentUnavailableView(
            "App Settings",
            systemImage: "gearshape",
            description: Text("\(snippets.count) snippet\(snippets.count == 1 ? "" : "s") saved. Adjust editor and default-language preferences on the left.")
        )
    }
}
