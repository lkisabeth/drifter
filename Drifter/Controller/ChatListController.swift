//
//  ChatListController.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/10/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import BFTransmitter
import ChameleonFramework
import Firebase
import MessageKit
import TransitionButton
import UIKit
import IGListKit

private let itemHeight: CGFloat = 84
private let lineSpacing: CGFloat = 20
private let topInset: CGFloat = 10

private var peersFile: String = "peersFile"
private var messageTextKey: String = "message_text"
private var peerNameKey: String = "peer_name"
private var peerIdKey: String = "peer_id"
private var peerTypeKey: String = "peer_type"
private var messageIdKey: String = "message_id"

open class ChatListController: UIViewController, ListAdapterDataSource, ListAdapterMoveDelegate, NearbyPeersSectionControllerDelegate, BFTransmitterDelegate, DirectChatViewControllerDelegate, DriftChatViewControllerDelegate {
    
    fileprivate var openUUID: String = ""
    fileprivate var openStateOnline: Bool = true
    fileprivate var transmitter: BFTransmitter
    fileprivate var peerNamesDictionary: NSMutableDictionary
    fileprivate var onlinePeers: [Peer]
    fileprivate weak var chatController: DirectChatViewController?
    
    var currentUser = Auth.auth().currentUser!
    
    var refreshControl: UIRefreshControl?
    
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
        return onlinePeers
    }
    
    public func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        let sectionController = NearbyPeersSectionController(isReorderable: true)
        sectionController.delegate = self
        return sectionController
    }
    
    public func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
    
    // MARK: - Interactive Reordering
    @available(iOS 9.0, *)
    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            let touchLocation = gesture.location(in: self.collectionView)
            guard let selectedIndexPath = collectionView.indexPathForItem(at: touchLocation) else {
                break
            }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            if let view = gesture.view {
                let position = gesture.location(in: view)
                collectionView.updateInteractiveMovementTargetPosition(position)
            }
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    
    // MARK: - ListAdapterMoveDelegate
    public func listAdapter(_ listAdapter: ListAdapter, move object: Any, from previousObjects: [Any], to objects: [Any]) {
        guard let objects = objects as? [Peer] else { return }
        onlinePeers = objects
    }

    
    public required init?(coder aDecoder: NSCoder) {
        // Transmitter initialization
        self.transmitter = BFTransmitter(apiKey: "ed18b2d0-8a19-4ad6-9dce-311b66b13d99")
        self.peerNamesDictionary = NSMutableDictionary()
        self.onlinePeers = [Peer]()
        super.init(coder: aDecoder)
        self.transmitter.delegate = self
        self.transmitter.isBackgroundModeEnabled = true
        // Load demo related data and register for background enter
        self.loadPeers()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        _ = adapter
        if #available(iOS 9.0, *) {
            adapter.moveDelegate = self
        }

        title = "Nearby"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatListController.savePeers),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        let logOutButton = UIBarButtonItem(title: "Log Out", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.logOut(_:)))
        navigationItem.leftBarButtonItem = logOutButton

        addRefreshControl()
        self.transmitter.start()
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
        self.openUUID = peer.identifier
        let chatController = DirectChatViewController()

        navigationController?.pushViewController(chatController, animated: true)
        let directMessages = self.loadMessagesForConversation(openUUID)
        for message in directMessages {
            message.kind = .text(message.messageBody)
            message.sender = Sender(id: message.senderId, displayName: message.displayName)
            print(message.sender)
        }
        chatController.messages = directMessages
        chatController.userUUID = self.openUUID
        chatController.chatDelegate = self
        self.chatController = chatController
    }
    
    // MARK: ChatViewControllerDelegate
    
    open func sendMessage(_ message: Message, toConversation uuid: String) {
        var dictionary: Dictionary<String, Any>
        var receiverUUID: String?
        var options: BFSendingOption
        
        receiverUUID = uuid
        options = [.fullTransmission, .encrypted]
        // Creation of the dictionary for the message to be sent
        dictionary = [messageTextKey: message.messageBody,
                      peerIdKey: currentUser.uid as Any,
                      peerNameKey: currentUser.displayName as Any,
                      peerTypeKey: DeviceType.ios.rawValue,
                      messageIdKey: message.messageId]
        
        do {
            try self.transmitter.send(dictionary, toUser: receiverUUID, options: options)
        } catch let err as NSError {
            print("Error: \(err)")
        }
        
        message.senderId = currentUser.uid
        message.displayName = currentUser.displayName!
        // Just persistence management
        self.saveMessage(message, forConversation: uuid)
    }
    
    // MARK: BFTransmitterDelegate
    
    public func transmitter(_ transmitter: BFTransmitter, meshDidAddPacket packetID: String) {
        // Packet added to mesh
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didReachDestinationForPacket packetID: String) {
        // Mesh packet reached destiny (no always invoked)
    }
    
    public func transmitter(_ transmitter: BFTransmitter, meshDidStartProcessForPacket packetID: String) {
        // A message entered in the mesh process.
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didSendDirectPacket packetID: String) {
        // A direct message was sent
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didFailForPacket packetID: String, error: Error?) {
        // A direct message transmission failed.
    }
    
    public func transmitter(_ transmitter: BFTransmitter, meshDidDiscardPackets packetIDs: [String]) {
        // A mesh message was discared and won't still be transmitted.
    }
    
    public func transmitter(_ transmitter: BFTransmitter, meshDidRejectPacketBySize packetID: String) {
        print("The packet \(packetID) was rejected from mesh because it exceeded the limit size.")
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didReceive dictionary: [String: Any]?, with data: Data?, fromUser user: String, packetID: String, broadcast: Bool, mesh: Bool) {
        // A dictionary was received by BFTransmitter.
        if dictionary?[messageTextKey] != nil {
            // If it contains a value for the key messageTextKey it's a message
            self.processReceivedMessage(dictionary!,
                                        fromUser: user, byMesh: mesh, asBroadcast: broadcast)
        } else {
            // If it doesn't contain the key messageTextKey it's the device name of the other user.
            self.processReceivedPeerInfo(dictionary!, fromUser: user)
        }
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didDetectConnectionWithUser user: String) {
        // A connection was detected (no necessarily secure)
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didDetectDisconnectionWithUser user: String) {
        self.discardUUID(user)
        adapter.performUpdates(animated: true, completion: nil)
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didFailAtStartWithError error: Error) {
        print("An error occurred at start: \(error.localizedDescription)")
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didOccur event: BFEvent, description: String) {
        print("Event reported: \(description)")
    }
    
    public func transmitter(_ transmitter: BFTransmitter, shouldConnectSecurelyWithUser user: String) -> Bool {
        return true // if true establish connection with encryption capacities.
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didDetectSecureConnectionWithUser user: String) {
        // A secure connection was detected,
        // A secure connection has encryption capabilities.
        
        // Check if there's a name saved for this user.
        self.processName(forUser: user)
        
        // Update the collection accord this new connection
        if self.peerNamesDictionary[user] == nil {
            self.peerNamesDictionary.setValue("", forKey: user)
        }
        
        self.discardUUID(user)
        adapter.performUpdates(animated: true, completion: nil)
    }
    
    // MARK: Name and message utils
    
    func processName(forUser user: String) {
        // If there's not a name a temporary name is assigned
        // meanwhile the real name is received.
        
        if self.peerNamesDictionary[user] == nil {
            let tmpName = "Id: \((user as NSString).substring(to: 5))"
            let peerInfo = ["name": tmpName as Any,
                            "type": DeviceType.undefined.rawValue]
            self.peerNamesDictionary[user] = peerInfo
        }
        
        // In case the other user don't have our devicename,
        // this is sent as an initial message.
        sendDeviceNameToUser(user)
    }
    
    func sendDeviceNameToUser(_ user: String) {
        let dictionary = [peerNameKey: currentUser.displayName as Any,
                          peerIdKey: currentUser.uid as Any,
                          peerTypeKey: DeviceType.ios.rawValue]
        let options: BFSendingOption = [.directTransmission, .encrypted]
        
        do {
            try self.transmitter.send(dictionary, toUser: user, options: options)
        } catch let err as NSError {
            print("Error: \(err)")
        }
    }
    
    func processReceivedMessage(_ dictionary: Dictionary<String, Any>, fromUser user: String, byMesh mesh: Bool, asBroadcast broadcast: Bool) {
        // Processing a new message
        let text: String = dictionary[messageTextKey] as! String
        let messageId: String = dictionary[messageIdKey] as! String
        let peerId: String = dictionary[peerIdKey] as! String
        let peerName: String = dictionary[peerNameKey] as! String
        let message = Message(messageId: messageId, messageBody: text, sentDate: Date())
        message.senderId = peerId
        message.displayName = peerName
        message.sender = Sender(id: peerId, displayName: peerName)
        message.kind = .text(text)
        message.received = true
        message.mesh = mesh
        message.broadcast = broadcast // If YES received message is broadcast.
        
        let conversation: String = user
        self.saveMessage(message, forConversation: conversation)
        
        // YES if the related conversation for the user is shown
        let showingSameUser = self.chatController != nil && self.chatController?.userUUID == user
        if showingSameUser {
            // If the related conversation to the message is being shown.
            // update messages.
            self.chatController!.insertMessage(message)
        }
    }
    
    func processReceivedPeerInfo(_ peerInfo: Dictionary<String, Any>, fromUser user: String) {
        let existingDeviceName = (self.peerNamesDictionary[user] as! Dictionary<String, Any>)["name"] as! String
        let receivedDeviceName = peerInfo[peerNameKey] as! String
        let receivedDeviceType = peerInfo[peerTypeKey] as! Int
        
        if receivedDeviceName != existingDeviceName {
            let name = "\(receivedDeviceName) (\((user as NSString).substring(to: 5)))"
            let userInfo: Dictionary<String, Any> = ["name": name,
                                                     "type": receivedDeviceType]
            self.peerNamesDictionary.setValue(userInfo, forKey: user)
            let peer = Peer(identifier: user, displayName: peerInfo[peerNameKey] as! String)
            self.onlinePeers.append(peer)
            adapter.performUpdates(animated: true, completion: nil)
        }
    }
    
    // MARK: Clumsy data management
    
    func discardUUID(_ uuid: String) {
        if let peerToBeRemoved = self.onlinePeers.firstIndex(where: { $0.identifier == uuid }) {
            self.onlinePeers.remove(at: peerToBeRemoved)
        }
        adapter.performUpdates(animated: true, completion: nil)
    }
    
    func saveMessage(_ message: Message, forConversation conversation: String) {
        let filePath = self.fullPathForFile(conversation)
        var messages: [Message] = self.loadMessagesForConversation(conversation)
        messages.append(message)
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        coder.encode(messages, forKey: NSKeyedArchiveRootObjectKey)
        let data = coder.encodedData
        try? data.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
    }
    
    func loadMessagesForConversation(_ conversation: String) -> [Message] {
        let filePath = self.fullPathForFile(conversation)
        let data: Data? = try? Data(contentsOf: URL(fileURLWithPath: filePath))
        let loadedMessages: [Message]
        if data != nil {
            loadedMessages = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data!) as! [Message]
        } else {
            loadedMessages = [Message]()
        }
        return loadedMessages
    }
    
    @objc func savePeers() {
        let filePath = self.fullPathForFile(peersFile)
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        coder.encode(self.peerNamesDictionary, forKey: NSKeyedArchiveRootObjectKey)
        let data = coder.encodedData
        try? data.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
    }
    
    func loadPeers() {
        let filePath = self.fullPathForFile(peersFile)
        let data: Data? = try? Data(contentsOf: URL(fileURLWithPath: filePath))
        if data != nil {
            self.peerNamesDictionary = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data!) as! NSMutableDictionary
        } else {
            self.peerNamesDictionary = NSMutableDictionary()
        }
    }
    
    func fullPathForFile(_ file: String) -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = URL(fileURLWithPath: path)
        return url.appendingPathComponent(file).path
    }
}
