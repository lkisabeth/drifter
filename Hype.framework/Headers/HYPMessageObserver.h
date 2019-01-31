//
// Copyright (C) 2015 Hype Labs - All Rights Reserved
//
// NOTICE: All information contained herein is, and remains the property of
// Hype Labs. The intellectual and technical concepts contained herein are
// proprietary to Hype Labs and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret and copyright law.
// Dissemination of this information or reproduction of this material is
// strictly forbidden unless prior written permission is obtained from
// Hype Labs.
//

#import <Foundation/Foundation.h>

@class HYP;
@class HYPMessage;
@class HYPInstance;
@class HYPMessageInfo;
@class HYPError;

/**
 * Message observers listen to message events, such as messages being received,
 * sent, delivered, or failing. The concepts of "sending" and "delivering" are
 * important to distinguish. A message being "sent" indicates that it was written
 * to the output streams, but not necessarily delivered to it's destination. This
 * only means that the content is circulating on the network, or that it might
 * not have left the device yet. A message being "delivered", on the other hand,
 * indicates that its destination has acknowledge reception and the content is
 * already available on the end device. Messages being written to the output
 * streams are indicated by the `-hype:didSendMessage:toInstance:progress:complete:`
 * event. A message being delivered is indicated by `-hype:didDeliverMessage:toInstance:progress:complete:`.
 * Hype does not yet support progress tracking on the receiving end, meaning
 * that the destination only gets the message when it has been fully dilevered.
 * Other events include messages being received using `-hype:didReceiveMessage:fromInstance:`
 * or failed sending, with `-hype:didFailSendingMessage:toInstance:error:`.
 */
@protocol HYPMessageObserver <NSObject>

/**
 * This notification is issued when a message arrives. The framework passes
 * the data as it is received and makes no attempt of processing it (other
 * than encrypting and decrypting it, when applicable). The instance parameter
 * indicates the originating instance.
 * @param message A container for the data and metadata for the message received.
 * @param fromInstance The instance from which the data originated.
 */
- (void)hypeDidReceiveMessage:(HYPMessage *)message
                 fromInstance:(HYPInstance *)fromInstance;

/**
 * This notification is issued when a message is known to have failed being sent
 * to the network. This means that the message never entirely left the device,
 * and as such it will not be received by the destination. Common causes for this
 * include the destination instance being lost while the content is being sent,
 * causing the output streams to close. Hype does not implement failed delivery
 * notifications yet, meaning that even if this notification is not issued the message
 * may still not reach its destination. The `messageInfo` (`HYPMessageInfo`) parameter
 * holds some metadata about the original message. Currently, it only holds the
 * message's identifier, but more data can be used in the future. If the original
 * message was kept, the identifiers can be compared in order to map the event
 * with message's content. This is motivated by the fact that Hype does not keep
 * the message's data in order to save memory.
 * @param messageInfo A container for the data and metadata for the message being sent.
 * @param toInstance The instance to which the message was intented.
 * @param error An error indicating the cause of failure.
 */
- (void)hypeDidFailSendingMessage:(HYPMessageInfo *)messageInfo
                       toInstance:(HYPInstance *)toInstance
                            error:(HYPError *)error;

@optional

/**
 * This notification indicates that the message with the identifier given by the
 * `messageInfo` parameter has progressed in being sent to the network. This does
 * not mean that it has been delivered, but rather that it was written to the
 * streams. As such, the content could still be buffered waiting for output,
 * meaning that it might not have left the device yet. The delegate method
 * `-hype:didDeliverMessage:progress:complete:`, on the other hand, indicates delivery
 * to the receiving end. That method is preferred if the intent is to track delivery,
 * especially when messages are being sent over a mesh network and not direct link.
 * At this point, it's not known whether the content has been or will be delivered.
 * The progress indicator yields a number between 0 and 1, indicating the percentage
 * of the message that has been written to the streams. The `complete` boolean
 * argument indicates whether the message was fully written, in order to avoid
 * floating-point arithmetic. When looking for completion, use this flag instead
 * of using comparison over the progress float. The progress float is intended
 * for implementing loading bars and the likes of it. The `messageInfo` instance
 * maps to a message identifier of an `HYPMessage` instance that was returned by
 * the `-sendData:toInstance:trackProgress:` method. In order to keep track of which
 * messages are sent, store this identifier in a data structure and wait for
 * notifications with the same identifier. This step is, however, optional.
 * @param messageInfo Metadata about the message being sent.
 * @param toInstance The destination instance.
 * @param progress Percentage of content of the original message that was written.
 * @param complete Whether the message was fully written to the output streams.
 */
- (void)hypeDidSendMessage:(HYPMessageInfo *)messageInfo
                toInstance:(HYPInstance *)toInstance
                  progress:(float)progress
                  complete:(BOOL)complete;

/**
 * This notification indicates that the message with the identifier given by the
 * `messageInfo` parameter has progressed in reaching its destination. The amount
 * of data that has been delivered is indicated by the `progress` argument. This
 * argument holds a value between 0 and 1, indicating the percentage of the data
 * that the destination has acknowledge back to the origin. This notification is
 * only triggered if the `trackProgress` of the `-sendData:toInstance:trackProgress:`
 * is set to `YES`. As acknowledgements incur extra overhead on the network, this
 * option must be explicitly set. A value of 1 could indicate completion, but
 * the preferred method is to check the `complete` flag, thus avoid floating-point
 * arithmetic. Notice that the destination only gets a notification when the message
 * is fully received (`-hype:didReceiveMessage:fromInstance:`). This will change in
 * future release, and progress bars will be possible on both the originating and
 * receiving devices.
 * @param messageInfo Metadata about the message being delivered.
 * @param toInstance The destination instance.
 * @param progress Percentage of content of the original message that was delivered.
 * @param complete Whether the message was fully delivered to the destination.
 */
- (void)hypeDidDeliverMessage:(HYPMessageInfo *)messageInfo
                   toInstance:(HYPInstance *)toInstance
                     progress:(float)progress
                     complete:(BOOL)complete;

@end
