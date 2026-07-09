//
//  StructGeneratorView.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import SwiftUI

struct StructGeneratorView: View {
    @ObservedObject var document: JSONEditorViewModel
    @Binding var selectedLanguage: OutputLanguage
    @StateObject private var viewModel = StructGeneratorViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Convert to Type").font(.title2.bold())
                Spacer()
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(OutputLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)
            }
            .padding([.top, .horizontal])

            HStack {
                Text("Root type name")
                TextField("Root", text: $viewModel.rootTypeName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)
                Spacer()
                Button {
                    Clipboard.copy(generatedCode)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
            .padding(.horizontal)

            Divider()

            ScrollView {
                Text(generatedCode)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }

    private var generatedCode: String {
        viewModel.generatedCode(for: document.parsedValue, language: selectedLanguage)
    }
}
