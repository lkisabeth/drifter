//
//  ChatListController.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/10/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import UIKit
import BFTransmitter
import Firebase
import ChameleonFramework
import TransitionButton
import VegaScrollFlowLayout

var peersFile = "peersfile"
var messageTextKey = "messageBody"
var peerNameKey = "device_name"
var peerTypeKey = "device_type"

private let itemHeight: CGFloat = 84
private let lineSpacing: CGFloat = 20
private let xInset: CGFloat = 20
private let topInset: CGFloat = 10

open class ChatListController: UICollectionViewController, BFTransmitterDelegate, ChatViewControllerDelegate {
    
    fileprivate var openUUID: String = ""
    fileprivate var openStateOnline: Bool = true
    fileprivate var transmitter: BFTransmitter
    fileprivate var peerNamesDictionary: NSMutableDictionary
    fileprivate var onlinePeers: NSMutableArray
    fileprivate weak var chatController: ChatViewController? = nil
    fileprivate let cellId = "PeerCell"
    
    public required init?(coder aDecoder: NSCoder) {
        //Transmitter initialization
        self.transmitter = BFTransmitter(apiKey: "ed18b2d0-8a19-4ad6-9dce-311b66b13d99")
        self.peerNamesDictionary = NSMutableDictionary()
        self.onlinePeers = NSMutableArray()
        super.init(coder: aDecoder)
        self.transmitter.delegate = self
        self.transmitter.isBackgroundModeEnabled = true
        //Load demo related data and register for background enter
        self.loadPeers()
    }
    
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    override open func didReceiveMemoryWarning() {
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

    override open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.onlinePeers.count
    }
    
    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
        let itemWidth = UIScreen.main.bounds.width - 2 * xInset
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: collection view delegate
    
    override open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Prepares to open a conversation with a concrete user.
        openUUID = self.onlinePeers.object(at: indexPath.item) as! String
        self.performSegue(withIdentifier: "openContactChat", sender: self)
    }
    
    // MARK: ChatViewControllerDelegate
    
    open func sendMessage(_ message: Message, toConversation uuid: String) {
        var dictionary: Dictionary<String, Any>
        var receiverUUID: String?
        var options: BFSendingOption
        if message.broadcast {
            //A broadcast message don't have a concrete receiver
            //this is sent to all peers. For this reason
            //receiverUUID is nil.
            receiverUUID = nil
            // The encryption option is not included because a broadcast message can't
            // be encrypted.
            options = [.fullTransmission, .broadcastReceiver]
            
            // Creation of the dictionary for the message to be sent
            // We included the device name because is possible that
            // the final receiver doesn't have it.
            dictionary = [
                messageTextKey: message.messageBody,
                peerNameKey: UIDevice.current.name,
                peerTypeKey: DeviceType.ios.rawValue
            ]
            
        } else {
            // The message isn't not broadcast, instead is a direct message.
            // A direct message can be encrypted.
            receiverUUID = uuid
            options = [.fullTransmission, .encrypted]
            // Creation of the dictionary for the message to be sent
            dictionary = [messageTextKey: message.messageBody]
        }
        
        do {
            try self.transmitter.send(dictionary, toUser: receiverUUID, options: options)
        }
        catch let err as NSError {
            print("Error: \(err)")
        }
        
        //Just persistence management
        self.saveMessage(message, forConversation: uuid)
    }
    
    // MARK: Segue Methods
    
    override open func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        let chatController = segue.destination as! ChatViewController
        if segue.identifier == "openContactChat" {
            // Conversation with a concrete user.
            chatController.online = openStateOnline
            chatController.userUUID = openUUID
            let peerInfo: Dictionary<String, Any> = self.peerNamesDictionary[openUUID] as! Dictionary
            chatController.deviceName = peerInfo["name"] as! String
            chatController.deviceType = DeviceType(rawValue: peerInfo["type"] as! Int)!
            chatController.messages = self.loadMessagesForConversation(openUUID)
            chatController.broadcastType = false
        } else {
            // Broadcast conversation
            // (the messages will be sent to all available users)
            chatController.online = openStateOnline
            chatController.userUUID = "broadcast";
            chatController.messages = self.loadMessagesForConversation(broadcastConversation)
            chatController.broadcastType = true
        }
        chatController.chatDelegate = self
        self.chatController = chatController
    }
    
    // MARK: BFTransmitterDelegate
    public func transmitter(_ transmitter: BFTransmitter, meshDidAddPacket packetID: String) {
        //Packet added to mesh
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didReachDestinationForPacket packetID: String) {
        //Mesh packet reached destiny (no always invoked)
    }
    
    public func transmitter(_ transmitter: BFTransmitter, meshDidStartProcessForPacket packetID: String) {
        //A message entered in the mesh process.
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didSendDirectPacket packetID: String) {
        //A direct message was sent
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didFailForPacket packetID: String, error: Error?) {
        //A direct message transmission failed.
    }
    
    public func transmitter(_ transmitter: BFTransmitter, meshDidDiscardPackets packetIDs: [String]) {
        //A mesh message was discared and won't still be transmitted.
    }
    
    public func transmitter(_ transmitter: BFTransmitter, meshDidRejectPacketBySize packetID: String) {
        print("The packet \(packetID) was rejected from mesh because it exceeded the limit size.");
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didReceive dictionary: [String : Any]?, with data: Data?, fromUser user: String, packetID: String, broadcast: Bool, mesh: Bool) {
        
        
        // A dictionary was received by BFTransmitter.
        if (dictionary?[messageTextKey] != nil) {
            // If it contains a value for the key messageTextKey it's a message
            processReceivedMessage(dictionary! ,
                                   fromUser: user, byMesh: mesh, asBroadcast: broadcast)
        } else {
            //If it doesn't contain the key messageTextKey it's the device name of the other user.
            processReceivedPeerInfo(dictionary!, fromUser: user)
        }
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didDetectConnectionWithUser user: String) {
        //A connection was detected (no necessarily secure)
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didDetectDisconnectionWithUser user: String) {
        self.discardUUID(user)
        self.collectionView.reloadData()
        if self.chatController != nil &&
            self.chatController!.userUUID == user {
            //If currently a the related conversation is shown,
            //update the state.
            self.chatController!.updateOnlineTo(false)
        }
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didFailAtStartWithError error: Error)
    {
        print("An error occurred at start: \(error.localizedDescription)");
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didOccur event: BFEvent, description: String)
    {
        print("Event reported: \(description)");
    }
    
    public func transmitter(_ transmitter: BFTransmitter, shouldConnectSecurelyWithUser user: String) -> Bool {
        return true //if true establish connection with encryption capacities.
    }
    
    public func transmitter(_ transmitter: BFTransmitter, didDetectSecureConnectionWithUser user: String) {
        // A secure connection was detected,
        // A secure connection has encryption capabilities.
        
        // Check if there's a name saved for this user.
        processName(forUser: user)
        
        //Update the collection accord this new connection
        if self.peerNamesDictionary[user] == nil {
            self.peerNamesDictionary.setValue("", forKey: user)
        }
        
        self.discardUUID(user)
        self.onlinePeers.add(user)
        self.collectionView.reloadData()
        if self.chatController != nil &&
            self.chatController!.userUUID == user {
            //If currently a the related conversation is shown,
            //update the state.
            self.chatController!.updateOnlineTo(true)
        }
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
        let dictionary = [peerNameKey: UIDevice.current.name as Any,
                          peerTypeKey: DeviceType.ios.rawValue]
        let options: BFSendingOption = [.directTransmission, .encrypted]
        
        do {
            try self.transmitter.send(dictionary, toUser: user, options: options)
        }
        catch let err as NSError {
            print("Error: \(err)")
        }
        
    }
    
    func processReceivedMessage(_ dictionary: Dictionary<String, Any>, fromUser user: String, byMesh mesh: Bool, asBroadcast broadcast: Bool) {
        
        // Processing a new message
        let text: String = dictionary[messageTextKey] as! String
        let message = Message()
        message.messageBody = text
        message.received = true
        message.date = Date()
        message.mesh = mesh
        message.broadcast = broadcast// If YES received message is broadcast.
        
        let conversation: String
        if message.broadcast {
            conversation = broadcastConversation
            let deviceType = DeviceType(rawValue: dictionary[peerTypeKey] as! Int)!
            message.deviceType = deviceType
            // The deviceName will be processed because it's possible we don't have it yet.
            processReceivedPeerInfo(dictionary, fromUser: user)
        } else {
            conversation = user
        }
        let peerInfo = self.peerNamesDictionary[user] as! Dictionary<String, Any>
        message.sender = peerInfo["name"] as! String
        self.saveMessage(message, forConversation: conversation)
        
        // YES if the related conversation for the user is shown
        let showingSameUser = !message.broadcast &&
            self.chatController != nil &&
            self.chatController?.userUUID == user
        // YES if received message is for broadcast and broadcast is shown
        let showingBroadcast = message.broadcast &&
            self.chatController != nil &&
            self.chatController!.broadcastType
        if showingBroadcast || showingSameUser {
            // If the related conversation to the message is being shown.
            // update messages.
            self.chatController!.addMessage(message)
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
        let messages: NSMutableArray = self.loadMessagesForConversation(conversation)
        messages.insert(message, at: 0)
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        coder.encode(messages, forKey: NSKeyedArchiveRootObjectKey)
        let data = coder.encodedData
        try? data.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
    }
    
    func loadMessagesForConversation(_ conversation: String) -> NSMutableArray {
        let filePath = self.fullPathForFile(conversation)
        let data: Data? = try? Data(contentsOf: URL(fileURLWithPath: filePath))
        let messages: NSMutableArray
        if data != nil {
            messages = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data!) as! NSMutableArray
        } else {
            messages = NSMutableArray()
        }
        return messages
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
        if (data != nil) {
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
