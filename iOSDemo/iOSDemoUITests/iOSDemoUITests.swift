import XCTest

class ExtoleWebViewTest: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        identifyUser()
        navigateToWebView()
    }

    func testEmailShare() throws {
        let emailButton = self.app.webViews.buttons["email"]
        XCTAssert(emailButton.waitForExistence(timeout: 25))

        emailButton.tap()

        let messagePredicate = NSPredicate(format: "value CONTAINS[c] %@", "Sign up")
        let messageText = self.app.textViews.matching(messagePredicate)
        XCTAssert(messageText.element.waitForExistence(timeout: 25))
    }

    func testNativeShare() throws {
        let nativeShareButton = self.app.webViews.buttons["native"]
        XCTAssert(nativeShareButton.waitForExistence(timeout: 25))

        nativeShareButton.tap()

        let copyMessageButton = self.app.staticTexts["Copy"]
        XCTAssert(copyMessageButton.waitForExistence(timeout: 25))

        let messageTextField = self.app.staticTexts["Messages"]
        XCTAssert(messageTextField.waitForExistence(timeout: 15))
    }

    private func identifyUser() {
        let emailTextField = app.textFields.element(boundBy: 0)
        let userEmailAddress = "extole.monitor.user@extole.com\n"
        emailTextField.tap()
        emailTextField.typeText(userEmailAddress)
    }

    private func navigateToWebView() {
        let openWebViewButtonCondition = NSPredicate(format: "label CONTAINS[c] %@", "Check this out")
        let openWebViewButton = app.buttons.matching(openWebViewButtonCondition)
        XCTAssert(openWebViewButton.element.waitForExistence(timeout: 15))
        openWebViewButton.element.tap()
    }
}
