//
//  Message.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/9/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import UIKit
import Firebase

enum DeviceType: Int {
    case undefined = 0
    case android
    case ios
}

open class Message: NSObject, NSSecureCoding {
    
    public static var supportsSecureCoding: Bool = true
    
    var sender: String
    var messageBody: String
    var received: Bool
    var date: Date
    var mesh: Bool
    var broadcast: Bool
    var deviceType: DeviceType
    
    var dictionary: [String: Any] {
        return [
            "sender": sender,
            "messageBody": messageBody,
            "received": received,
            "date": date,
            "mesh": mesh,
            "broadcast": broadcast,
            "deviceType": deviceType
        ]
    }
    
    override required public init()
    {
        self.sender = ""
        self.messageBody = ""
        self.received = false
        self.date = Date()
        self.mesh = false
        self.broadcast = false
        self.deviceType = .undefined
        
        super.init()
    }
    
    required public init(coder decoder: NSCoder) {
        self.sender =  decoder.decodeObject(forKey: "sender") as! String
        self.messageBody = decoder.decodeObject(forKey: "messageBody") as! String
        self.received = Bool(decoder.decodeBool(forKey: "received") )
        self.date = decoder.decodeObject(forKey: "date") as! Date
        self.mesh = Bool(decoder.decodeBool(forKey: "mesh") )
        self.broadcast = Bool(decoder.decodeBool(forKey: "broadcast") )
        self.deviceType = DeviceType(rawValue: Int(decoder.decodeInteger(forKey: "device_type") ))!
    }
    
    open func encode(with encoder: NSCoder) {
        encoder.encode(self.sender, forKey: "sender")
        encoder.encode(self.messageBody, forKey: "messageBody")
        encoder.encode(self.received, forKey: "received")
        encoder.encode(self.date, forKey: "date")
        encoder.encode(self.mesh, forKey: "mesh")
        encoder.encode(self.broadcast, forKey: "broadcast")
        encoder.encode(self.deviceType.rawValue, forKey: "device_type")
    }
    
}
