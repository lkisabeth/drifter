//
//  NearbyPeersSectionController.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/20/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import UIKit
import IGListKit

protocol NearbyPeersSectionControllerDelegate: class {
    func didSelect(_ object: Any?)
}

class NearbyPeersSectionController: ListSectionController {
    weak var delegate: NearbyPeersSectionControllerDelegate?

    private var peer: Peer?
    private let isReorderable: Bool
    
    required init(isReorderable: Bool = false) {
        self.isReorderable = isReorderable
        super.init()
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: collectionContext!.containerSize.width, height: 100)
    }
    
    override func numberOfItems() -> Int {
        return 1 // One peer will be represented by one cell
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let cell = collectionContext?.dequeueReusableCell(of: PeerCell.self, for: self, at: index) as? PeerCell else {
            fatalError()
        }
        cell.layer.cornerRadius = cell.bounds.height / 2
        cell.text = String(data: peer!.instance.announcement, encoding: .utf8)!
        return cell
    }
    
    
    override func didUpdate(to object: Any) {
        self.peer = object as? Peer
    }
    
    override func didSelectItem(at index: Int) {
        delegate?.didSelect(peer)
    }
    
    override func canMoveItem(at index: Int) -> Bool {
        return true
    }
}
