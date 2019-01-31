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

/**
 * Instances map to devices participating on the network. Instances are
 * advertised on the network and, when found, a notification is issued
 * indicating that the instance is available for communication purposes.
 * Usually, there's no need to instantiate objects of this type at all,
 * as the framework handles that automatically. Instance identifiers are
 * unique for each device, and are divided in three parts: an app identifier,
 * a device identifier, and a user identifier. The app identifier is always
 * the same, as Hype fragments the network using that, so the app never needs
 * to deal with instances from different vendors. Device identifiers are
 * automatically assigned by the SDK. The user identifier is a custom optional
 * setting, and can be used to help identify the user running an unresolved
 * instance, although that consists of a 31bit (not 32!) that can be used
 * for any purpose the app may need. Collectively, the three identifiers
 * form what is called a "global identifier", which can be queried with
 * the `- identifier` property. Such identifiers are between 6 and 12 bytes
 * long and uniquely identify each device on the network.
 */
@interface HYPInstance : NSObject

/**
 * This property indicates the app identifier the instance is participating
 * in. This identifier is exclusive to this app, as the framework handles
 * devices with different identifiers transparently and never propagates
 * them to the app. All found instances have the same identifier, one that
 * is equal to that of the host device. App identifiers are always 2 or 4
 * bytes long and may never be null.
 */
@property (atomic, readonly) NSData * appIdentifier;

/**
 * This property yields the instance's app identifier using an hexadecimal
 * encoding.
 */
@property (atomic, copy) NSString * appStringIdentifier;

/**
 * User identifiers are custom properties set by the app that identify the
 * user running it. This field gives the value set for the user on the app
 * matching to this instance.
 */
@property (atomic, readonly) NSUInteger userIdentifier;

/**
 * This property yields an identifier that is unique for each instance on
 * the network.
 */
@property (atomic, readonly) NSData * identifier;

/**
 * This property yields the instance's identifier in string form. The string
 * is the data object written using hexadecimal notation.
 */
@property (atomic, copy) NSString * stringIdentifier;

/**
 * Announcements circulate on the network to help the app identify participating
 * devices. This is similar to a `userIdentifier`, and it can be considered as an
 * extra space for identification purposes. The main difference is that user
 * identifiers are present even before the instance is resolved, while announcements
 * are not. The SDK optimizes the flooding of announcements on the network by caching
 * it on router devices.
 */
@property (atomic, readonly) NSData * announcement;

/**
 * Indicates whether the instance has already been resolved. If not, communicating
 * with it is not possible. Such instances must be resolved before iniciating a
 * conversation.
 */
@property (atomic) BOOL isResolved;

/**
 * Initializes an instance object with a given identifier and announcement. There's
 * no reason to use this method and manually instantiate this class. The SDK handles
 * that automatically.
 * @param identifier Instance identifier.
 * @param announcement The instance's announcement.
 * @returns The initialized instance.
 */
- (instancetype)initWithIdentifier:(NSData *)identifier
                      announcement:(NSData *)announcement
                        isResolved:(BOOL)isResolved;

@end
