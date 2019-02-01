//
//  ExtoleApp.swift
//  firstapp
//
//  Created by rtibin on 1/25/19.
//  Copyright © 2019 rtibin. All rights reserved.
//

import Foundation
import os.log

class ExtoleApp {
    
    let modelLog = OSLog.init(subsystem: "com.extole", category: "model")
    
    public enum State {
        case Init
        case Inactive
        case InvalidToken
        case ServerError
        case Online
        case Identified
        case ReadyToShare
        case Busy
    }
    
    private let program = Program.init(baseUrl: URL.init(string: "https://roman-tibin-test.extole.com")!)
    
    private let label = "refer-a-friend"
    
    private let settings = UserDefaults.init()
    
    let notification = NotificationCenter.init()
    
    var state = State.Init {
        didSet {
            notification.post(name: Notification.Name.state, object: self)
        }
    }
    
    private let dispatchQueue = DispatchQueue(label : "Extole", qos:.background)
    
    static let `default` = ExtoleApp()
    
    var savedToken : String? {
        get {
            return settings.string(forKey: "extole.access_token")
        }
        set(newSavedToken) {
            settings.set(newSavedToken, forKey: "extole.access_token")
        }
    }
    
    var accessToken: ConsumerToken?
    var profile: MyProfile?
    var selectedShareable : MyShareable?
    var lastShareResult: CustomSharePollingResult?
    
    func applicationDidBecomeActive() {
        os_log("applicationDidBecomeActive", log: appLog, type: .info)
        dispatchQueue.async {
            if let existingToken = self.savedToken {
                self.program.getToken(token: existingToken) { token, error in
                    if let verifiedToken = token {
                        self.onVerifiedToken(verifiedToken: verifiedToken)
                    }
                    if let verifyTokenError = error {
                        switch(verifyTokenError) {
                            case .invalidAccessToken : self.onTokenInvalid()
                            default: self.onServerError()
                        }
                    }
                }
            } else {
                self.program.getToken() { (token, error) in
                    if let newToken = token {
                        self.onVerifiedToken(verifiedToken: newToken)
                    }
                }
            }
        }
    }
    
    func onTokenInvalid() {
        self.state = State.InvalidToken
        self.savedToken = nil
        self.program.getToken(){ token, error in
            if let newToken = token {
                self.onVerifiedToken(verifiedToken: newToken)
            }
        }
    }

    func logout() {
        program.deleteToken(token: self.savedToken!) { token, error in
            if let _ = token {
                self.savedToken = nil
                self.state = .Inactive
                self.profile = nil
                self.selectedShareable = nil
                self.lastShareResult = nil
            }
            
        }
    }

    func onServerError() {
        self.state = State.ServerError
    }

    func onVerifiedToken(verifiedToken: ConsumerToken) {
        self.savedToken = verifiedToken.access_token
        self.accessToken = verifiedToken
        self.state = State.Online
        self.program.getProfile(accessToken: verifiedToken)
            .onComplete { (profile: MyProfile?) in
                if let identified = profile, !(identified.email?.isEmpty ?? true) {
                    self.onProfileIdentified(identified: identified)
                }
        }
    }

    func updateProfile(profile: MyProfile) {
        dispatchQueue.async {
            self.state = State.Busy
            self.program.updateProfile(accessToken: self.accessToken!, profile: profile).onComplete { (_: SuccessResponse?) in
                if !(profile.email?.isEmpty ?? true) {
                    self.onProfileIdentified(identified: profile)
                }
            }
        }
    }

    func signalEmailShare() {
        os_log("shared via system-email", log: modelLog, type: .info)
    }
    
    func signalMessageShare() {
        os_log("shared via system-message", log: modelLog, type: .info)
    }
    
    func signalFacebookShare() {
        os_log("shared via system-facebook", log: modelLog, type: .info)
    }
    
    func signalShare(channel: String) {
        os_log("shared via custom channel %s", log: modelLog, type: .info, channel)
    }
    
    func share(recepient: String, message: String) {
        dispatchQueue.async {
            let share = CustomShare.init(advocate_code: self.selectedShareable!.code!, channel: "EMAIL", message: message, recipient_email: recepient, data: [:])
            self.state = State.Busy
            self.program.customShare(accessToken: self.accessToken!, share: share)
                .onComplete(callback: { (pollingResponse: PollingIdResponse?) in
                    self.program.pollCustomShare(accessToken: self.accessToken!, pollingResponse: pollingResponse!).onComplete(callback: { (shareResult: CustomSharePollingResult?) in
                        self.state = State.ReadyToShare
                        self.lastShareResult = shareResult
                    })
            })
        }
    }
    
    func onProfileIdentified(identified: MyProfile) {
        self.profile = identified
        self.state = State.Identified
        self.program.getShareables(accessToken: accessToken!).onComplete(callback: onShareablesLoaded)
    }
    
    func onShareablesLoaded(shareables: [MyShareable]?) {
        if let shareable = shareables?.filter({ (shareable : MyShareable) -> Bool in
            return shareable.label == self.label
        }).first {
            self.selectedShareable = shareable
            self.state = State.ReadyToShare
        } else {
            let newShareable = MyShareable.init(label: self.label,
                                                key: self.label)
            self.program.createShareable(accessToken: accessToken!, shareable: newShareable).onComplete { (pollingId: PollingIdResponse?) in
                self.program.pollShareable(accessToken: self.accessToken!, pollingResponse: pollingId!).onComplete(callback: { (shareableResult: ShareablePollingResult?) in
                    self.program.getShareables(accessToken: self.accessToken!).onComplete(callback: self.onShareablesLoaded)
                })
            }
        }
    }
    
    func applicationWillResignActive() {
        os_log("application resign active", log: modelLog, type: .info)
        self.state = .Inactive
    }
}
