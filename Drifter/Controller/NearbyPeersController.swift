//
//  NearbyPeersController.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/10/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import Firebase
import MessageKit
import TransitionButton
import UIKit
import IGListKit
import Hype

private var peersFile: String = "peersFile"
private var messageTextKey: String = "message_text"
private var peerNameKey: String = "peer_name"
private var peerIdKey: String = "peer_id"
private var peerTypeKey: String = "peer_type"
private var messageIdKey: String = "message_id"

open class NearbyPeersController: UIViewController, HYPStateObserver, HYPNetworkObserver, HYPMessageObserver, ListAdapterDataSource, NearbyPeersSectionControllerDelegate {

    var peers = [String: Peer]()
    var currentUser = Auth.auth().currentUser!
    var announcement: String = ""
    
    var refreshControl: UIRefreshControl?
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        adapter.performUpdates(animated: true, completion: nil)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        _ = adapter
        
        self.announcement = (currentUser.displayName! as String)

        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        navigationController?.navigationBar.topItem?.title = "Nearby People"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        let logOutButton = UIBarButtonItem(title: "Log Out", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.logOut(_:)))
        navigationItem.leftBarButtonItem = logOutButton
        addRefreshControl()

        requestHypeToStart()
    }
    
    func requestHypeToStart() {
        HYP.add(self as HYPStateObserver)
        HYP.add(self as HYPNetworkObserver)
        HYP.add(self as HYPMessageObserver)
        
        HYP.setAnnouncement(self.announcement.data(using: .utf8))
        
        HYP.setAppIdentifier("e76e4743")
        HYP.start()
    }
    
    public func hypeDidRequestAccessToken(withUserIdentifier userIdentifier: UInt) -> String! {
        return "86c06c56d193c7be"
    }
    
    public func hypeDidStart() {
        NSLog("Hype started!")
    }
    
    public func hypeDidStopWithError(_ error: HYPError!) {
        let description: String! = error == nil ? "" : error.description
        NSLog("Hype stopped [%@]", description)
    }
    
    public func hypeDidFailStartingWithError(_ error: HYPError!) {
        NSLog("Hype failed starting [%@]", error.description)
        
        let errorMessage : String = "Description: " + (error.description as String) + "\nReason:" + (error.reason as String)  + "\nSuggestion:" + (error.suggestion as String)
        let alert = UIAlertController(title: "Hype failed starting", message: errorMessage, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    public func hypeDidBecomeReady() {
        NSLog("Hype is ready")
        
        // We're here due to a failed start request, try again..
        requestHypeToStart()
    }
    
    private func hypeDidChangeState() {
        NSLog("Hype state changed to \(HYP.state().rawValue) (Idle=0, Starting=1, Running=2, Stopping=3")
    }

    func shouldResolveInstance(_ instance: HYPInstance!) -> Bool {
        // This method can be used to decide whether an instance is interesting
        return true
    }
    
    public func hypeDidFind(_ instance: HYPInstance!) {
        NSLog("Hype found instance: [%@]", instance.stringIdentifier)
        
        // Resolve instances that matter
        if shouldResolveInstance(instance) {
            HYP.resolve(instance)
        }
    }
    
    public func hypeDidLose(_ instance: HYPInstance!, error: HYPError!) {
        DispatchQueue.main.async {
            let description: String! = error == nil ? "" : error.description
            NSLog("Hype Lost instance: %@ [%@]", instance.stringIdentifier, description)
            
            // Clean up
            self.removeFromResolvedInstancesDict(instance)
        }
    }

    public func hypeDidResolve(_ instance: HYPInstance!) {
        NSLog("Hype resolved instance: [%@]", instance.stringIdentifier)
        
        // This device is now capable of communicating
        addToResolvedInstancesDict(instance)
    }
    
    public func hypeDidFailResolving(_ instance: HYPInstance!, error: HYPError!) {
        let description:String! = error == nil ? "" : error.description
        NSLog("Hype failed resolving instance: %@ [%@]", instance.stringIdentifier, description)
    }
    
    public func hypeDidReceive(_ message: HYPMessage!, from fromInstance: HYPInstance!) {
        DispatchQueue.main.async {
            NSLog("Hype got a message from: [%@]", fromInstance.stringIdentifier)
            
            let peer = self.peers[fromInstance.stringIdentifier]
            
            // Storing the message triggers a reload update in the chat view controller
            peer?.add(message, isMessageReceived: true)

            self.adapter.performUpdates(animated: true, completion: nil)
        }
    }
    
    public func hypeDidFailSendingMessage(_ messageInfo: HYPMessageInfo!, to toInstance: HYPInstance!, error: HYPError!) {
        NSLog("Hype failed to send message: %@ [%@]", UInt(messageInfo.identifier), error.description)
    }
    
    private func hypeDidSendMessage(_ messageInfo: HYPMessageInfo!, to toInstance: HYPInstance!, progress: Float, complete: Bool) {
        NSLog("Hype is sending a message: \(progress)")
    }
    
    private func hypeDidDeliverMessage(_ messageInfo: HYPMessageInfo!, to toInstance: HYPInstance!, progress: Float, complete: Bool) {
        
        NSLog("Hype delivered a message: \(progress)")
    }
    
    func addToResolvedInstancesDict(_ instance: HYPInstance) {
        DispatchQueue.main.async {
            self.peers.updateValue(Peer (instance: instance), forKey: instance.stringIdentifier)
            
            // Reloading the table reflects the change
            self.adapter.performUpdates(animated: true, completion: nil)
        }
    }
    
    func removeFromResolvedInstancesDict(_ instance: HYPInstance) {
        DispatchQueue.main.async {
            self.peers.removeValue(forKey: instance.stringIdentifier)
            
            // Reloading the table reflects the change
            self.adapter.performUpdates(animated: true, completion: nil)
        }
    }

    // Setup for IGListKit (data driven collection view)
    @IBOutlet weak var collectionView: UICollectionView!
    lazy var adapter: ListAdapter =  {
        let updater = ListAdapterUpdater()
        let adapter = ListAdapter(updater: updater,
                                  viewController: self,
                                  workingRangeSize: 1)
        adapter.collectionView = collectionView
        adapter.dataSource = self
        return adapter
    }()
    
    public func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        var diffablePeers = [ListDiffable]()
        for peer in peers {
            diffablePeers.append(peer.value)
        }
        return diffablePeers
    }
    
    public func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        let sectionController = NearbyPeersSectionController(isReorderable: false)
        sectionController.delegate = self
        return sectionController
    }
    
    public func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
    
    func addRefreshControl() {
        collectionView.refreshControl = UIRefreshControl()
        collectionView.alwaysBounceVertical = true
        collectionView.refreshControl?.layer.zPosition = -1
        collectionView.refreshControl?.tintColor = UIColor.primaryColor
        collectionView.refreshControl?.attributedTitle = NSAttributedString(string: "Double checking for more people..")
        collectionView.refreshControl?.addTarget(self, action: #selector(refreshPeers), for: .valueChanged)
    }
    
    @objc func refreshPeers() {
        collectionView.refreshControl?.beginRefreshing()
        adapter.performUpdates(animated: true, completion: { (completed) in
            self.collectionView.refreshControl?.endRefreshing()
        })
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func logOut(_ sender: AnyObject) {
        try! Auth.auth().signOut()
        if let storyboard = self.storyboard {
            let vc = storyboard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
            self.present(vc, animated: false, completion: nil)
        }
    }
    
    // MARK: collection view delegate
    
    func didSelect(_ object: Any?) {
        let peer = object as! Peer
        let vc = DirectChatViewController()

        navigationController?.pushViewController(vc, animated: true)
        print(String(peer.instance.stringIdentifier))
        print(String(data: peer.instance.announcement, encoding: .utf8)!)
        vc.peer = peer
        for message in peer.messages {
            vc.messages.append(message)
        }
    }

    // MARK: Clumsy data management
    
    @objc func savePeers() {
        let filePath = self.fullPathForFile(peersFile)
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        coder.encode(self.peers, forKey: NSKeyedArchiveRootObjectKey)
        let data = coder.encodedData
        try? data.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
    }
    
    func loadPeers() {
        let filePath = self.fullPathForFile(peersFile)
        let data: Data? = try? Data(contentsOf: URL(fileURLWithPath: filePath))
        if data != nil {
            self.peers = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data!) as! [String: Peer]
        } else {
            self.peers = [String: Peer]()
        }
    }
    
    func fullPathForFile(_ file: String) -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = URL(fileURLWithPath: path)
        return url.appendingPathComponent(file).path
    }
}
