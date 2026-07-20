//
//  ExtractView.swift
//  JsonLens
//
//  Created by Six Johann  on 20/07/2026.
//
//  Select fields from an array of JSON objects and export them as CSV.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ExtractView: View {
    @ObservedObject var document: JSONEditorViewModel
    @StateObject private var viewModel = ExtractViewModel()
    @State private var showingCopyConfirmation = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""

    var body: some View {
        Group {
            if let error = document.error {
                ContentUnavailableView(
                    "Can't extract from invalid JSON",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Line \(error.line), column \(error.column): \(error.message)")
                )
            } else if document.parsedValue == nil {
                ContentUnavailableView(
                    "Paste JSON in the editor",
                    systemImage: "tablecells",
                    description: Text("Choose an array and its fields to create a CSV file.")
                )
            } else if viewModel.sources.isEmpty {
                ContentUnavailableView(
                    "No object arrays found",
                    systemImage: "rectangle.3.group",
                    description: Text("CSV extraction needs an array containing JSON objects."))
            } else {
                extractor
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { viewModel.update(for: document.parsedValue) }
        .onChange(of: document.text) { _, _ in
            viewModel.update(for: document.parsedValue)
        }
        .alert("Couldn’t Save CSV", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage)
        }
    }
    private var extractor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Extract CSV")
                        .font(.title2.bold())
                    Text("Select an object array and the fields to export.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    downloadCSV()
                } label: {
                    Label("Download CSV", systemImage: "arrow.down.document")
                }
                .disabled(viewModel.csvPreview.isEmpty)
                .help("Download CSV")

                Spacer()
                Button {
                    Clipboard.copy(viewModel.csvPreview)
                    showingCopyConfirmation = true
                } label: {
                    Label("Copy CSV", systemImage: "doc.on.doc")
                }
                .disabled(viewModel.csvPreview.isEmpty)
                .popover(isPresented: $showingCopyConfirmation, arrowEdge: .bottom) {
                    Text("CSV copied")
                        .font(.caption)
                        .padding(8)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                showingCopyConfirmation = false
                            }
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top)

            HStack {
                Text("Array")
                Picker("Array", selection: $viewModel.selectedSourcePath) {
                    ForEach(viewModel.sources) { source in
                        Text("\(source.path) · \(source.rows.count) rows")
                            .tag(Optional(source.path))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 280)
                .onChange(of: viewModel.selectedSourcePath) { _, path in
                    if let source = viewModel.sources.first(where: { $0.path == path }) {
                        viewModel.selectSource(source)
                    }
                }
                Text("Separator")
                Picker("Separator", selection: $viewModel.separator) {
                    ForEach(ExtractSeparator.allCases) { separator in
                        Text(separator.title).tag(separator)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 150)
            }
            .padding(.horizontal)

            Divider()

            VSplitView {
                fieldSelector
                    .frame(minHeight: 80)
                csvPreview
                    .frame(minHeight: 180)
            }
        }
    }

    private var fieldSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Columns")
                .font(.headline)
            Text("Choose the fields to include in each CSV row.")
                .font(.caption)
                .foregroundStyle(.secondary)

            List {
                ForEach(viewModel.selectedSource?.fieldNames ?? [], id: \.self) { field in
                    Toggle(field, isOn: Binding(
                        get: { viewModel.selectedFields.contains(field) },
                        set: { viewModel.setField(field, isSelected: $0) }
                    ))
                    .font(.system(.body, design: .monospaced))
                }
            }
            .listStyle(.inset)
        }
        .padding(.leading)
        .padding(.bottom)
    }

    private var csvPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CSV Preview · \(viewModel.separator.title)")
                .font(.headline)
            Text("\(viewModel.selectedSource?.rows.count ?? 0) rows · \(viewModel.selectedFields.count) columns")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView([.horizontal, .vertical]) {
                Text(viewModel.csvPreview.isEmpty ? "Select at least one column." : viewModel.csvPreview)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.separator, lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func defaultFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "CSV-Export-\(formatter.string(from: .now)).csv"
    }

    private func downloadCSV() {
        let csv = viewModel.csvPreview
        guard !csv.isEmpty else { return }

        let panel = NSSavePanel()
        panel.title = "Save CSV"
        panel.prompt = "Save"
        panel.nameFieldStringValue = defaultFileName()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.allowsOtherFileTypes = false
        panel.canCreateDirectories = true
        panel.directoryURL = FileManager.default.urls(
            for: .downloadsDirectory,
            in: .userDomainMask
        ).first

        guard panel.runModal() == .OK, let destination = panel.url else { return }

        do {
            try csv.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
        }
    }
}
