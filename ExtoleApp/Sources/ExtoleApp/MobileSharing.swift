//Copyright © 2019 Extole. All rights reserved.

import Foundation

extension ExtoleApp {
    public class MobileSharing: Codable {
        public class Data: Codable {
          let me: [String: String]
        }
        let event_id: String
        let data: Data
    }
}
