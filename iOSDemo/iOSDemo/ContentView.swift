import SwiftUI
import ExtoleMobileSDK

struct ContentView: View {
    @EnvironmentObject var extoleCampaign: ExtoleCampaign
    @State private var showWebView = false
    var body: some View {
        NavigationStack {
            VStack {
                Button("Open WebView") {
                    showWebView = true
                }
            }
            .navigationDestination(isPresented: $showWebView) {
                ContentWebView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
