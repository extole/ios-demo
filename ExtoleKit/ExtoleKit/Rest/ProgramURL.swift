//Copyright © 2019 Extole. All rights reserved.

import Foundation

@objc public final class ProgramURL : NSObject {
    let baseUrl: URL
    let network : Network
    @objc public init(baseUrl: URL, network: Network = Network.init()) {
        self.baseUrl = baseUrl
        self.network = network
    }
}
