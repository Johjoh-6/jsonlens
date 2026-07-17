//
//  StructGeneratorViewModel.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import Foundation
internal import Combine

final class StructGeneratorViewModel: ObservableObject {
    @Published var rootTypeName: String = "Root"

    func generatedCode(for value: JSONValue?, language: OutputLanguage) -> String {
        guard let value else { return "// Paste valid JSON in the editor to generate code" }
        guard let root = TypeModelBuilder.build(from: value, rootName: rootTypeName) else {
            return "// Root JSON must be an object, or an array of objects"
        }
        return language.generator.generate(root: root)
    }
}
