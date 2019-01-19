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
import VegaScrollFlowLayout

private let itemHeight: CGFloat = 84
private let lineSpacing: CGFloat = 20
private let topInset: CGFloat = 10

private var peersFile: String = "peersFile"
private var messageTextKey: String = "message_text"
private var peerNameKey: String = "peer_name"
private var peerIdKey: String = "peer_id"
private var peerTypeKey: String = "peer_type"
private var messageIdKey: String = "message_id"

open class ChatListController: UICollectionViewController, BFTransmitterDelegate, DirectChatViewControllerDelegate {
    fileprivate var openUUID: String = ""
    fileprivate var openStateOnline: Bool = true
    fileprivate var transmitter: BFTransmitter
    fileprivate var peerNamesDictionary: NSMutableDictionary
    fileprivate var onlinePeers: NSMutableArray
    fileprivate weak var chatController: DirectChatViewController?
    fileprivate let cellId = "PeerCell"
    
    var currentUser = Auth.auth().currentUser!
    
    public required init?(coder aDecoder: NSCoder) {
        // Transmitter initialization
        self.transmitter = BFTransmitter(apiKey: "ed18b2d0-8a19-4ad6-9dce-311b66b13d99")
        self.peerNamesDictionary = NSMutableDictionary()
        self.onlinePeers = NSMutableArray()
        super.init(coder: aDecoder)
        self.transmitter.delegate = self
        self.transmitter.isBackgroundModeEnabled = true
        // Load demo related data and register for background enter
        self.loadPeers()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        self.collectionView.setNeedsLayout()
        self.collectionView.layoutIfNeeded()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Nearby Peers"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatListController.savePeers),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        let logOutButton = UIBarButtonItem(title: "Log Out", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.logOut(_:)))
        navigationItem.leftBarButtonItem = logOutButton
        
        let nib = UINib(nibName: cellId, bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellId)
        collectionView.contentInset.bottom = itemHeight
        configureCollectionViewLayout()
        
        self.transmitter.start()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
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
    
    // MARK: Collection view data source
    
    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.onlinePeers.count
    }
    
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PeerCell
        
        let identifier: String = self.onlinePeers.object(at: indexPath.item) as! String
        let peerInfo = self.peerNamesDictionary[identifier] as! Dictionary<String, Any>
        
        cell.configureWith(peerInfo)
        
        return cell
    }
    
    private func configureCollectionViewLayout() {
        guard let layout = collectionView.collectionViewLayout as? VegaScrollFlowLayout else { return }
        layout.minimumLineSpacing = lineSpacing
        layout.sectionInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        let itemWidth = view.safeAreaLayoutGuide.layoutFrame.width
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: collection view delegate
    
    open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Prepares to open a direct conversation with a single user
        self.openUUID = self.onlinePeers.object(at: indexPath.item) as! String
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
        self.collectionView.reloadData()
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
        self.onlinePeers.add(user)
        self.collectionView.reloadData()
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
        self.sendDeviceNameToUser(user)
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
            self.collectionView.reloadData()
        }
    }
    
    // MARK: Clumsy data management
    
    func discardUUID(_ uuid: String) {
        if self.onlinePeers.index(of: uuid) != NSNotFound {
            self.onlinePeers.remove(uuid)
        }
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
