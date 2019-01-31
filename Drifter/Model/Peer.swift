//
//  Peer.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/16/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import Foundation
import IGListKit
import Hype

class Peer {
    var identifier: String
    weak var delegate: PeerDelegate?
    private(set)var messages = [HYPMessage]()
    var instance: HYPInstance
    var lastReadIndex: Int = 0

    init(instance: HYPInstance) {
        self.identifier = UUID().uuidString
        self.instance = instance
        lastReadIndex = 0
    }
    
    func add(_ message: HYPMessage, isMessageReceived: Bool) {
        
        messages.append(message)
        
        if (!isMessageReceived && self.lastReadIndex == self.messages.count-1) {
            self.lastReadIndex = self.messages.count // Avoid NewContent indicator to be activated when the message to be added to the store was sent by this instance
        }
        
        delegate?.didAdd(sender: self, message: message, isMessageReceived: isMessageReceived)
    }
    
    
    func hasNewMessages() -> Bool {
        return lastReadIndex < messages.count
    }
    
    func allMessages() -> [HYPMessage] {
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
