//
//  Message.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/9/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import Firebase
import MessageKit
import UIKit

class Message: MessageType {
    // sender and kind are required by the MessageKit SDK being used for chat
    public var sender: Sender = Sender(id: "", displayName: "")
    public var kind: MessageKind = .text("")
    public var messageId: String = ""
    public var sentDate: Date = Date()
}
