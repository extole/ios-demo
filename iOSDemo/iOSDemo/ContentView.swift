import SwiftUI
import ExtoleMobileSDK

struct ContentView: View {
    @EnvironmentObject var extoleCampaign: ExtoleCampaign
    var body: some View {
        NavigationView {
            VStack {
                Text(extoleCampaign.cta.subject)
                    .padding()
                Spacer()
                Text(extoleCampaign.cta.message)
                    .padding()
            }.task {
                extoleCampaign.fetch()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
