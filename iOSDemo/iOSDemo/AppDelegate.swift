import Foundation
import SwiftUI
import ExtoleMobileSDK

class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {
    @Published var extole: Extole = ExtoleImpl(programDomain: "https://simplepractivedemo.extole.io", applicationName: "iOS Demo App")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
