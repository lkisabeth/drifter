//
//  Message.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/9/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import Foundation
import Firebase

struct Message {
    
    var sender: String
    var messageBody: String // Could become an enum
    
    var dictionary: [String: Any] {
        return [
            "sender": sender,
            "messageBody": messageBody
        ]
    }
    
}

extension Message {
    
    init?(dictionary: [String : Any]) {
        guard let sender = dictionary["sender"] as? String,
            let messageBody = dictionary["messageBody"] as? String else { return nil }
        
        self.init(sender: sender,
                  messageBody: messageBody)
    }
    
}
