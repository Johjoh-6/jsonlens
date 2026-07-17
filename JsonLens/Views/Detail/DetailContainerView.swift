//
//  DetailContainerView.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import SwiftUI

struct DetailContainerView: View {
    @ObservedObject var appViewModel: AppViewModel

    var body: some View {
        Group {
            switch appViewModel.selectedTool {
            case .visualize:
                VisualizeView(document: appViewModel.document)
            case .generateType:
                StructGeneratorView(document: appViewModel.document,
                                     selectedLanguage: $appViewModel.selectedLanguage)
            case .compare:
                CompareView(document: appViewModel.document, comparison: appViewModel.compareRight)
            case .validate:
                ValidatorView(document: appViewModel.document)
            case .history:
                HistoryDetailView(appViewModel: appViewModel)
            case .setting:
                EmptyView()
            }
        }
        .frame(minWidth: 340)
    }
}
