//
//  DirectChatViewController.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/17/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import BFTransmitter
import Firebase
import MapKit
import MessageInputBar
import MessageKit
import UIKit

public protocol DirectChatViewControllerDelegate: NSObjectProtocol {
    func sendMessage(_ message: Message, toConversation uuid: String)
}

open class DirectChatViewController: BaseChatViewController {
    open weak var chatDelegate: DirectChatViewControllerDelegate?
    let currentUser = Auth.auth().currentUser!
    var userUUID: String = ""

    open override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
    }
    open override func viewDidLoad() {
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: CustomMessagesFlowLayout())
        messagesCollectionView.register(CustomCell.self)
        if let layout = messagesCollectionView.collectionViewLayout as? CustomMessagesFlowLayout {
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            let labelInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            layout.textMessageSizeCalculator.incomingMessageTopLabelAlignment = .init(textAlignment: .left, textInsets: labelInsets)
            layout.textMessageSizeCalculator.incomingMessageBottomLabelAlignment = .init(textAlignment: .left, textInsets: labelInsets)
            layout.textMessageSizeCalculator.outgoingMessageTopLabelAlignment = .init(textAlignment: .right, textInsets: labelInsets)
            layout.textMessageSizeCalculator.outgoingMessageBottomLabelAlignment = .init(textAlignment: .right, textInsets: labelInsets)
        }
        super.viewDidLoad()

        messagesCollectionView.scrollToBottom(animated: true)
        updateTitleView(title: "Direct Chat", subtitle: "Testing")
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func configureMessageCollectionView() {
        super.configureMessageCollectionView()
        
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.sectionInset = UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8)
        
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
    override func configureMessageInputBar() {
        super.configureMessageInputBar()
        
        messageInputBar.isTranslucent = true
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.inputTextView.tintColor = .primaryColor
        messageInputBar.inputTextView.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
        messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 36)
        messageInputBar.inputTextView.layer.borderColor = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1).cgColor
        messageInputBar.inputTextView.layer.borderWidth = 1.0
        messageInputBar.inputTextView.layer.cornerRadius = 16.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        configureInputBarItems()
    }
    
    private func configureInputBarItems() {
        messageInputBar.setRightStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.sendButton.imageView?.backgroundColor = UIColor(white: 0.85, alpha: 1)
        messageInputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        messageInputBar.sendButton.setSize(CGSize(width: 36, height: 36), animated: false)
        messageInputBar.sendButton.image = #imageLiteral(resourceName: "ic_up")
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.imageView?.layer.cornerRadius = 16
        messageInputBar.textViewPadding.right = -38
        let charCountButton = InputBarButtonItem()
            .configure {
                $0.title = "0/280"
                $0.contentHorizontalAlignment = .right
                $0.setTitleColor(UIColor(white: 0.6, alpha: 1), for: .normal)
                $0.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .bold)
                $0.setSize(CGSize(width: 50, height: 25), animated: false)
            }.onTextViewDidChange { item, textView in
                item.title = "\(textView.text.count)/280"
                let isOverLimit = textView.text.count > 280
                item.messageInputBar?.shouldManageSendButtonEnabledState = !isOverLimit // Disable automated management when over limit
                if isOverLimit {
                    item.messageInputBar?.sendButton.isEnabled = false
                }
                let color = isOverLimit ? .red : UIColor(white: 0.6, alpha: 1)
                item.setTitleColor(color, for: .normal)
            }
        let bottomItems = [makeButton(named: "ic_at"), makeButton(named: "ic_hashtag"), makeButton(named: "ic_library"), .flexibleSpace, charCountButton]
        messageInputBar.textViewPadding.bottom = 8
        messageInputBar.setStackViewItems(bottomItems, forStack: .bottom, animated: false)
        
        // This just adds some more flare
        messageInputBar.sendButton
            .onEnabled { item in
                UIView.animate(withDuration: 0.3) {
                    item.imageView?.backgroundColor = .primaryColor
                }
            }.onDisabled { item in
                UIView.animate(withDuration: 0.3) {
                    item.imageView?.backgroundColor = UIColor(white: 0.85, alpha: 1)
                }
            }
    }
    
    // MARK: - Helpers
    
    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        return indexPath.section % 3 == 0 && !isPreviousMessageSameSender(at: indexPath)
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messages[indexPath.section].sender == messages[indexPath.section - 1].sender
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messages.count else { return false }
        return messages[indexPath.section].sender == messages[indexPath.section + 1].sender
    }
    
    func setTypingIndicatorHidden(_ isHidden: Bool, performUpdates updates: (() -> Void)? = nil) {
        updateTitleView(title: "MessageKit", subtitle: isHidden ? "2 Online" : "Typing...")
        //        setTypingBubbleHidden(isHidden, animated: true, whilePerforming: updates) { [weak self] (_) in
        //            if self?.isLastSectionVisible() == true {
        //                self?.messagesCollectionView.scrollToBottom(animated: true)
        //            }
        //        }
        //        messagesCollectionView.scrollToBottom(animated: true)
    }
    
    private func makeButton(named: String) -> InputBarButtonItem {
        return InputBarButtonItem()
            .configure {
                $0.spacing = .fixed(10)
                $0.image = UIImage(named: named)?.withRenderingMode(.alwaysTemplate)
                $0.setSize(CGSize(width: 25, height: 25), animated: false)
                $0.tintColor = UIColor(white: 0.8, alpha: 1)
            }.onSelected {
                $0.tintColor = .primaryColor
            }.onDeselected {
                $0.tintColor = UIColor(white: 0.8, alpha: 1)
            }.onTouchUpInside { _ in
                print("Item Tapped")
            }
    }
    
    // MARK: - UICollectionViewDataSource
    
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard messagesCollectionView.messagesDataSource != nil else {
            fatalError("Ouch. nil data source for messages")
        }
        //        guard !isSectionReservedForTypingBubble(indexPath.section) else {
        //            return super.collectionView(collectionView, cellForItemAt: indexPath)
        //        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    // MARK: - MessagesDataSource
    
    public override func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isTimeLabelVisible(at: indexPath) {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
    
    public override func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isPreviousMessageSameSender(at: indexPath) {
            let name = message.sender.displayName
            return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
        return nil
    }
    
    public override func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isNextMessageSameSender(at: indexPath), isFromCurrentSender(message: message) {
            return NSAttributedString(string: "Delivered", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
        return nil
    }
}

// MARK: - MessagesDisplayDelegate

extension DirectChatViewController: MessagesDisplayDelegate {
    // MARK: - Text Messages
    
    public func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    public func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        return MessageLabel.defaultAttributes
    }
    
    public func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date, .transitInformation]
    }
    
    // MARK: - All Messages
    
    public func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .primaryColor : UIColor(red: 230 / 255, green: 230 / 255, blue: 230 / 255, alpha: 1)
    }
    
    public func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        var corners: UIRectCorner = []
        
        if isFromCurrentSender(message: message) {
            corners.formUnion(.topLeft)
            corners.formUnion(.bottomLeft)
            if !isPreviousMessageSameSender(at: indexPath) {
                corners.formUnion(.topRight)
            }
            if !isNextMessageSameSender(at: indexPath) {
                corners.formUnion(.bottomRight)
            }
        } else {
            corners.formUnion(.topRight)
            corners.formUnion(.bottomRight)
            if !isPreviousMessageSameSender(at: indexPath) {
                corners.formUnion(.topLeft)
            }
            if !isNextMessageSameSender(at: indexPath) {
                corners.formUnion(.bottomLeft)
            }
        }
        
        return .custom { view in
            let radius: CGFloat = 16
            let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            view.layer.mask = mask
        }
    }
    
    public func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // avatarView.set(avatar: avatar)
        avatarView.isHidden = true
        // avatarView.layer.borderWidth = 2
        // avatarView.layer.borderColor = UIColor.primaryColor.cgColor
    }
    
    // MARK: - Location Messages
    
    public func annotationViewForLocation(message: MessageType, at indexPath: IndexPath, in messageCollectionView: MessagesCollectionView) -> MKAnnotationView? {
        let annotationView = MKAnnotationView(annotation: nil, reuseIdentifier: nil)
        let pinImage = #imageLiteral(resourceName: "ic_map_marker")
        annotationView.image = pinImage
        annotationView.centerOffset = CGPoint(x: 0, y: -pinImage.size.height / 2)
        return annotationView
    }
    
    public func animationBlockForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> ((UIImageView) -> Void)? {
        return { view in
            view.layer.transform = CATransform3DMakeScale(2, 2, 2)
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [], animations: {
                view.layer.transform = CATransform3DIdentity
            }, completion: nil)
        }
    }
    
    public func snapshotOptionsForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LocationMessageSnapshotOptions {
        return LocationMessageSnapshotOptions(showsBuildings: true, showsPointsOfInterest: true, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
    }
}

// MARK: - MessagesLayoutDelegate

extension DirectChatViewController: MessagesLayoutDelegate {
    public func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if isTimeLabelVisible(at: indexPath) {
            return 18
        }
        return 0
    }
    
    public func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return !isPreviousMessageSameSender(at: indexPath) ? 20 : 0
    }
    
    public func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return (!isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message)) ? 16 : 0
    }
}

// MARK: - MessageInputBarDelegate

extension DirectChatViewController: MessageInputBarDelegate {
    public func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        for component in inputBar.inputTextView.components {
            if let str = component as? String {
                let message = Message(messageId: UUID().uuidString, messageBody: str, sentDate: Date())
                message.kind = .text(str)
                message.sender = currentSender()
                insertMessage(message)
                chatDelegate?.sendMessage(message, toConversation: userUUID)
            } else if let emoji = component as? String {
                let message = Message(messageId: UUID().uuidString, messageBody: emoji, sentDate: Date())
                message.kind = .emoji(emoji)
                message.sender = currentSender()
                insertMessage(message)
                chatDelegate?.sendMessage(message, toConversation: userUUID)
            }
        }
        inputBar.inputTextView.text = String()
        messagesCollectionView.scrollToBottom(animated: true)
    }
}
