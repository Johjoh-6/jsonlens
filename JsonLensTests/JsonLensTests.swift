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

    @Test func csvExtractionEscapesValuesAndLeavesMissingFieldsEmpty() throws {
        let json = try JSONParser.parse("""
        [
          { "username": "Ada, Lovelace", "dob": "1815-12-10", "note": "She said \\"hello\\"" },
          { "username": "Grace", "dob": "1906-12-09" }
        ]
        """).get()
        let source = try #require(ExtractService.sources(in: json).first)

        let csv = ExtractService.delimitedText(
            source: source,
            fields: ["username", "dob", "note"],
            separator: .comma
        )

        let expected = [
            "username,dob,note",
            "\"Ada, Lovelace\",1815-12-10,\"She said \"\"hello\"\"\"",
            "Grace,1906-12-09,"
        ].joined(separator: "\n")

        #expect(csv == expected)

        let semicolonSeparated = ExtractService.delimitedText(
            source: source,
            fields: ["username", "dob"],
            separator: .semicolon
        )
        #expect(semicolonSeparated == "username;dob\nAda, Lovelace;1815-12-10\nGrace;1906-12-09")
    }
}
