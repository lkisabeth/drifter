//
//  Peer.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/16/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import Foundation
import Firebase
import IGListKit
import Hype
import MessageKit

class Peer {
    var identifier: String
    weak var delegate: PeerDelegate?
    private(set)var messages = [Message]()
    var instance: HYPInstance
    var lastReadIndex: Int = 0
    let currentUser = Auth.auth().currentUser!

    init(instance: HYPInstance) {
        self.identifier = UUID().uuidString
        self.instance = instance
        lastReadIndex = 0
    }

    func add(_ message: HYPMessage, isMessageReceived: Bool) {
        let convertedMessage = Message()
        convertedMessage.kind = .text(String(data: message.data, encoding: .utf8)!)
        convertedMessage.messageId = UUID().uuidString
        if isMessageReceived {
            convertedMessage.sender = Sender(id: String(self.instance.stringIdentifier!), displayName: String(data: self.instance.announcement, encoding: .utf8)!)
        } else {
            convertedMessage.sender = Sender(id: currentUser.uid, displayName: currentUser.displayName!)
        }
        
        messages.append(convertedMessage)
        
        if (!isMessageReceived && self.lastReadIndex == self.messages.count-1) {
            self.lastReadIndex = self.messages.count // Avoid NewContent indicator to be activated when the message to be added to the store was sent by this instance
        }
        
        delegate?.didAdd(sender: self, message: convertedMessage, isMessageReceived: isMessageReceived)
    }
    
    
    func hasNewMessages() -> Bool {
        return lastReadIndex < messages.count
    }
    
    func allMessages() -> [Message] {
        return [] + self.messages
    }
}

extension Peer: ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        return identifier as NSString
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? Peer else {
            return false
        }
        return self.identifier == object.identifier
    }
}
