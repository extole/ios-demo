import Foundation
import SwiftUI
import ExtoleMobileSDK

class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {
    @Published var extole: Extole = ExtoleImpl(programDomain: "https://referral.moneybase.com", applicationName: "iOS Demo App")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
