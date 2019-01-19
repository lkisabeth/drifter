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

public enum DeviceType: Int {
    case undefined = 0
    case android
    case ios
}

open class Message: NSObject, NSSecureCoding, MessageType {
    public static var supportsSecureCoding: Bool = true
    
    // these two are required by the MessageKit SDK being used for chat (but I don't want to encode them)
    public var sender: Sender = Sender(id: "", displayName: "")
    public var kind: MessageKind = .text("")
    
    public var senderId: String
    public var displayName: String
    public var messageId: String
    public var messageBody: String
    public var sentDate: Date
    public var received: Bool
    public var mesh: Bool
    public var broadcast: Bool
    public var deviceType: DeviceType
    
    var dictionary: [String: Any] {
        return [
            "senderId": senderId,
            "displayName": displayName,
            "messageId": messageId,
            "messageBody": messageBody,
            "sentDate": sentDate,
            "received": received,
            "mesh": mesh,
            "broadcast": broadcast,
            "deviceType": deviceType
        ]
    }
    
    public required override init() {
        self.senderId = ""
        self.displayName = ""
        self.messageId = ""
        self.messageBody = ""
        self.sentDate = Date()
        self.received = false
        self.mesh = false
        self.broadcast = false
        self.deviceType = .undefined
        
        super.init()
    }
    
    public init(messageId: String, messageBody: String, sentDate: Date) {
        self.senderId = ""
        self.displayName = ""
        self.messageId = messageId
        self.messageBody = messageBody
        self.sentDate = sentDate
        self.received = false
        self.mesh = false
        self.broadcast = false
        self.deviceType = .ios
    }
    
    public required init(coder decoder: NSCoder) {
        self.senderId = decoder.decodeObject(forKey: "senderId") as! String
        self.displayName = decoder.decodeObject(forKey: "displayName") as! String
        self.messageId = decoder.decodeObject(forKey: "messageId") as! String
        self.messageBody = decoder.decodeObject(forKey: "messageBody") as! String
        self.sentDate = decoder.decodeObject(forKey: "sentDate") as! Date
        self.received = Bool(decoder.decodeBool(forKey: "received"))
        self.mesh = Bool(decoder.decodeBool(forKey: "mesh"))
        self.broadcast = Bool(decoder.decodeBool(forKey: "broadcast"))
        self.deviceType = DeviceType(rawValue: Int(decoder.decodeInteger(forKey: "device_type")))!
    }
    
    open func encode(with encoder: NSCoder) {
        encoder.encode(self.senderId, forKey: "senderId")
        encoder.encode(self.displayName, forKey: "displayName")
        encoder.encode(self.messageId, forKey: "messageId")
        encoder.encode(self.messageBody, forKey: "messageBody")
        encoder.encode(self.sentDate, forKey: "sentDate")
        encoder.encode(self.received, forKey: "received")
        encoder.encode(self.mesh, forKey: "mesh")
        encoder.encode(self.broadcast, forKey: "broadcast")
        encoder.encode(self.deviceType.rawValue, forKey: "device_type")
    }
}
