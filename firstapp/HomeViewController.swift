//
//  SessionViewController.swift
//  firstapp
//
//  Created by rtibin on 2/4/19.
//  Copyright © 2019 rtibin. All rights reserved.
//

import Foundation
import UIKit

let SHARE_MESSAGE_KEY = "app.shareMessage"

extension ExtoleApp {
    var shareMessage: String? {
        get {
            return settings.string(forKey: SHARE_MESSAGE_KEY)
        }
        set(newValue) {
            settings.setValue(newValue, forKey: SHARE_MESSAGE_KEY)
        }
    }
}

class HomeViewController : UITableViewController, ExtoleAppStateListener {

    func onStateChanged(state: ExtoleApp.State) {
        switch state {
        case .Identified:
            extoleApp.fetchObject(zone: "settings") { (settings: ShareSettings?, error) in
                self.extoleApp.shareMessage = settings?.shareMessage
                self.showState(app: self.extoleApp)
            }
        default:
            showState(app: extoleApp)
            break;
        }
    }
    
    var extoleApp: ExtoleApp!
    var refreshControlCompat: UIRefreshControl?
    
    var identifyViewController: IdentifyViewController!
    var profileViewController: ProfileViewController!
    var shareController : ShareViewController!
    
    let cellId = "cellId"
    
    struct MainSection {
        let name: String
        let controls: [()->String?]
    }
    
    func getIdentity() -> String {
        return "ID"
    }
    
    enum Section {
        case Identity
        case Profile
        case Share
        
        func getMainSection(app: ExtoleApp) -> MainSection{
            switch self {
            case .Identity:
                return MainSection(name: "Identity", controls: [{
                    return app.profile?.email}
                    ])
            case .Profile:
                return MainSection(name: "Profile", controls: [{
                        return app.profile?.first_name
                    }, {
                        return app.profile?.last_name
                    }])
            
            case .Share :
                return MainSection(name: "Share", controls: [{
                    return app.shareMessage
                }, {
                    return app.selectedShareable?.link
                }])
            }
        }
        
        func getEditController(controller: HomeViewController) -> UIViewController {
            switch self {
            case .Identity:
                return controller.identifyViewController
            case .Profile:
                return controller.profileViewController
            case .Share:
                return controller.shareController
            }
        }
    }
    
    let sections: [Section] = [.Identity, .Profile, .Share]
    
    init(with extoleApp: ExtoleApp) {
        self.extoleApp = extoleApp
        self.identifyViewController = IdentifyViewController.init(with : extoleApp)
        self.profileViewController = ProfileViewController.init(with : extoleApp)
        self.shareController = ShareViewController(with: extoleApp)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func nextClick(_ sender: UIButton) {
        navigationController?.pushViewController(shareController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Home"
        self.view.backgroundColor = UIColor.white
        
        extoleApp.stateListener = self

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        
        self.refreshControlCompat = UIRefreshControl()
        if #available(iOS 10.0, *) {
            self.tableView.refreshControl = refreshControlCompat
        } else {
            self.tableView.addSubview(refreshControlCompat!)
        }
        refreshControlCompat?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        showState(app: extoleApp)
        tableView.separatorStyle = .singleLine
    }
    
    @objc private func refreshData(_ sender: Any) {
        tableView.reloadData()
        self.refreshControlCompat?.endRefreshing()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let selectedSection = sections[section]
        return selectedSection.getMainSection(app: extoleApp).controls.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        let section = sections[indexPath.section]
        let value = section.getMainSection(app: extoleApp).controls[indexPath.row]()
        
        if let presentValue = value {
            cell.textLabel?.text = presentValue
            cell.textLabel?.isEnabled = true
        } else {
            cell.textLabel?.text = "(none)"
            cell.textLabel?.isEnabled = false
            
        }
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(sections[section])"
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let editController = section.getEditController(controller: self)
        
        self.navigationController?.pushViewController(
            editController, animated: false)
        
    }
    
    func showState(app: ExtoleApp) {
        DispatchQueue.main.async {
            self.navigationItem.title = "Home"
            self.tableView.reloadData()
            switch(app.state) {
            case .LoggedOut : do {
                let nextSession = UIBarButtonItem.init(title: "New", style: .plain, target: self, action: #selector(self.newSessionClick))
                self.navigationItem.rightBarButtonItem = nextSession
                self.navigationItem.leftBarButtonItem = nil
                }
            case .ReadyToShare : do {
                let logout = UIBarButtonItem.init(title: "Logout", style: .plain, target: self, action: #selector(self.logoutClick))
                self.navigationItem.leftBarButtonItem = logout
                
                let share = UIBarButtonItem.init(barButtonSystemItem: .action, target: self
                    , action: #selector(self.doShare))
                self.navigationItem.rightBarButtonItem = share
                }
            case .Identify: do {
                self.navigationItem.title = "Anonymous"
                let anonymous = UIBarButtonItem.init(title: "Generate Link", style: .plain, target: self, action: #selector(self.anonymousClick))
                self.navigationItem.rightBarButtonItem = anonymous
                self.navigationItem.leftBarButtonItem = nil
                }
            default: do {
                let logout = UIBarButtonItem.init(title: "Logout", style: .plain, target: self, action: #selector(self.logoutClick))
                self.navigationItem.leftBarButtonItem = logout
                self.navigationItem.title = "\(app.state)"
                }
            }
            
        }
    }
    
    @objc func anonymousClick(_ sender: UIButton) {
        extoleApp.updateProfile(profile: MyProfile.init()) { error in
            if let error = error {
                self.showError(message: "\(error)")
            }
        }
    }
    
    @objc func doShare(_ sender: UIButton) {
        guard let shareLink = extoleApp.selectedShareable?.link else {
            self.showError(message: "No Shareable")
            return
        }
        guard let message = extoleApp.shareMessage else {
            return
        }
        let shareItem = ShareItem.init(subject: "Check this out",
                                       message: message,
                                       shortMessage: shareLink)
        let textToShare = [ shareItem  ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        activityViewController.completionWithItemsHandler =  {(activityType : UIActivity.ActivityType?, completed : Bool, returnedItems: [Any]?, activityError : Error?) in
            if let completedActivity = activityType, completed {
                self.extoleApp.signalShare(channel: completedActivity.rawValue)
            }
        }
    }
    
    @objc func logoutClick(_ sender: UIButton) {
        let logoutConfimation = UIAlertController(title: "Logout", message: "Confirm logout.", preferredStyle: .actionSheet)
        
        logoutConfimation.addAction(UIAlertAction(title: NSLocalizedString("Yes, Log me out", comment: "Default action"), style: .destructive, handler: { _ in
            self.extoleApp.logout()
        }))
        logoutConfimation.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel action"), style: .cancel, handler: nil))
        self.present(logoutConfimation, animated: true, completion: nil)
    }
    
    @objc func newSessionClick(_ sender: UIButton) {
        extoleApp.newSession()
    }
}