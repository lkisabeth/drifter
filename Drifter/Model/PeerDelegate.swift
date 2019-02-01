//
//  PeerDelegate.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/30/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import Foundation
import Hype

protocol PeerDelegate: NSObjectProtocol {
    func didAdd(sender: Peer, message: Message, isMessageReceived: Bool)
}
