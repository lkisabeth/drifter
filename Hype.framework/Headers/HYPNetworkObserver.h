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
@class HYPInstance;
@class HYPError;

/**
 * Network observers handle network events, such as instances being found
 * and lost on the network.
 */
@protocol HYPNetworkObserver <NSObject>

/**
 * This notification is issued when an instance is found with a matching app
 * identifier. Instances on direct link are automatically resolved, while
 * instances found in mesh may not be. If the given instance is already resolved,
 * communicating with it is already possible, but attempting to do so should
 * only happen after a notification to the `-hypeDidResolveInstance:` delegate
 * callback. The app should resolve all instances that it wants to communicate
 * when this notification is triggered.
 * @param instance The found instance.
 */
- (void)hypeDidFindInstance:(HYPInstance *)instance;

/**
 * This notification is issued when a previously found instance is lost, such
 * as it going out of range, or the adapter being turned off. The error parameter
 * indicates the cause for the loss. When a cause cannot be properly determined
 * the framework uses a probable one instead, usually indicating that the device
 * appeared to go out of range.
 * @param instance The lost instance.
 * @param error An error describing the cause for the loss.
 */
- (void)hypeDidLoseInstance:(HYPInstance *)instance
                      error:(HYPError *)error;

/**
 * This notification indicates that the given instance has already been
 * resolved and is thus ready to communicate. The instance's announcement
 * and user identifier should help identify the user running the app. The
 * app should keep track of resolved instances, and clear them when they
 * are lost, as these instances are necessary in order to send messages.
 */
- (void)hypeDidResolveInstance:(HYPInstance *)instance;

/**
 * This delegate notification indicates that resolving an instance was not
 * possible. There are many scenarios under which that may happen, but they
 * are usually uncommon. A notable case is when the instance is lost during
 * the handshake process, invalidating it.
 * @param instance The instance that could not be resolved.
 * @param error An error indicating the cause for the failure.
 */
- (void)hypeDidFailResolvingInstance:(HYPInstance *)instance
                               error:(HYPError *)error;

@end

