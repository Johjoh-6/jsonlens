//
//  JsonLensUITests.swift
//  JsonLensUITests
//
//  Created by Six Johann on 10/06/2026.
//

import XCTest

final class JsonLensUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testTypeGeneratorShowsGuidanceBeforeJSONIsEntered() throws {
        let app = XCUIApplication()
        app.launch()

        let generatorTool = app.staticTexts["tool.generateType"]
        XCTAssertTrue(generatorTool.waitForExistence(timeout: 2))
        generatorTool.click()

        XCTAssertTrue(app.staticTexts["Paste JSON in the editor"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["structGenerator.copyButton"].isEnabled)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
