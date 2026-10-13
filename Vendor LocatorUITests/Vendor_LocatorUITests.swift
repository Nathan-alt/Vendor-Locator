import XCTest

final class Vendor_LocatorUITests: XCTestCase {
    @MainActor

    func testDemoWorkflow() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--vendors-fail-refresh-once"]
        app.launch()
        let favorite = app.buttons["Favorite Mr D Pizza — Cape Town CBD"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 10))
        favorite.tap()
        app.buttons["Reload vendors"].tap()
        XCTAssertTrue(app.buttons["Try again"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Unfavorite Mr D Pizza — Cape Town CBD"].exists)
        app.buttons["Try again"].tap()
        XCTAssertTrue(app.buttons["Search and add a place"].waitForExistence(timeout: 5))
        app.buttons["Search and add a place"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Waterfront")
        let result = app.buttons.containing(.staticText, identifier: "Waterfront Kitchen")
            .firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
        app.buttons["Settings"].tap()
        app.buttons["Clear token"].tap()
        app.secureTextFields["Session token"].tap()
        app.secureTextFields["Session token"].typeText("demo-test-token")
        app.buttons["Save securely"].tap()
        XCTAssertTrue(app.staticTexts["Token saved in Keychain."].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        app.buttons["Settings"].tap()
        app.buttons["Read and reveal stored token"].tap()
        XCTAssertTrue(app.staticTexts["demo-test-token"].waitForExistence(timeout: 5))
        app.buttons["Clear token"].tap()
        app.buttons["Read and reveal stored token"].tap()
        XCTAssertTrue(app.staticTexts["No token is stored."].waitForExistence(timeout: 5))
    }
}
