//
//  ShareItem.swift
//  firstapp
//
//  Created by rtibin on 2/5/19.
//  Copyright © 2019 rtibin. All rights reserved.
//

import Foundation
import UIKit

struct ShareSettings : Codable {
    let shareMessage: String
}

@objc class ShareItem : NSObject, UIActivityItemSource {
    let message: String
    let shortMessage: String
    let subject: String
    init (subject: String, message: String, shortMessage: String) {
        self.subject = subject
        self.message = message
        self.shortMessage = shortMessage
    }
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return shortMessage
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        switch activityType {
        case UIActivity.ActivityType.message: return shortMessage
        default: return message
        }
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return subject
    }
}