//
//  JsonLensTests.swift
//  JsonLensTests
//
//  Created by Six Johann on 10/06/2026.
//

import Testing
@testable import JsonLens

struct JsonLensTests {

    @Test func swiftGeneratorRendersInferredFields() throws {
        let json = try JSONParser.parse("""
        {
          "name": "Ada",
          "age": 37
        }
        """).get()

        let generated = StructGeneratorViewModel().generatedCode(for: json, language: .swift)

        #expect(generated == """
        struct Root: Codable {
            let name: String
            let age: Int
        }
        """)
    }

    @Test func everyLanguageDefinesPreviewKeywords() {
        for language in OutputLanguage.allCases {
            #expect(!language.generatedCodeKeywords.isEmpty, "\(language.rawValue) needs preview keywords")
        }
    }

    @Test func generatorExplainsUnsupportedRootValue() throws {
        let json = try JSONParser.parse("[1, 2, 3]").get()

        let generated = StructGeneratorViewModel().generatedCode(for: json, language: .swift)

        #expect(generated == "// Root JSON must be an object, or an array of objects")
    }
}
