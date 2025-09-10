import Foundation
import ExtoleMobileSDK

class ExtoleCampaign: ObservableObject {
    @Published var cta = CTA()
    var contextCampaign: Campaign?
    var extole: Extole

    public init(_ extole: Extole) {
        self.extole = extole
    }

    func fetch() {
        extole.fetchZone("advocate_mobile_experience", [:]) { (zone: ExtoleMobileSDK.Zone?, _: ExtoleMobileSDK.Campaign?, _: Error?) in
            let subject = zone?.get("sharing.email.subject") as! String? ?? "ERROR: EXTOLE REQUEST DIDN'T WORK"
            let message = zone?.get("sharing.email.message") as! String? ?? "ERROR: EXTOLE REQUEST DIDN'T WORK"
            self.cta = CTA(subject: subject, message: message)
        }
    }

    public func getWebView(zoneName: String) -> UIExtoleWebView {
        if nil != contextCampaign {
            return UIExtoleWebView(contextCampaign!.webView(), zoneName)
        } else {
            return UIExtoleWebView(extole.webView(), zoneName)
        }
    }
}
