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
@class HYPError;

/**
 * State observers handle Hype state change events, such as the framework
 * starting, and stopping, among others. This is helpful for tracking the
 * framework's lifecycle. The instance must be registered with the HYP
 * singleton using the method `-addStateObserver:`. Notifications include
 * Hype's life cycle.
 */
@protocol HYPStateObserver <NSObject>

/**
 * This notification is issued upon a successful call to `-start` on the
 * Hype singleton instance. When this notification is triggered, Hype
 * services are actively being advertised on the network and device matches
 * can occur at any time.
 */
- (void)hypeDidStart;

/**
 * This notification is issued when the Hype services are requested to stop,
 * or otherwise forced to do so. If the services were forced to stop (such
 * as the adapter being turned of) the error instance will indicate the
 * cause of failure. If this is being triggered due to a successful call to
 * `-stop`, then the error will be set to nil.
 * @param error An error (`HYPError`) indicating the cause for the stoppage, if any.
 */
- (void)hypeDidStopWithError:(HYPError *)error;

/**
 * This notification is issued in response to a failed start request. This means
 * that the device is not actively participating on the network with any transport
 * nor trying to recover from the failure. If, at some point, the framework finds
 * indications that recovery is possible, a `-hypeDidBecomeReady:` notification is
 * issued. Hype services will not start unless explicitly told to.
 * @param error An error (`HYPError`) indicating the cause of failure.
 */
- (void)hypeDidFailStartingWithError:(HYPError *)error;

/**
 * This notification is issued after a failed start request (that is, after
 * `-start` resulting in `-hypeDidFailStarting:error:`) and the framework
 * identifying that the cause of failure might not apply anymore. Attempting
 * to start the framework's services is not guaranteed to succeed as other
 * causes for failure might exist, but they are likely to do so. It's up to
 * the receiver to decide whether the services should be started. This event
 * is only triggered once and Hype stops listening to adapter state events.
 */
- (void)hypeDidBecomeReady;

/**
 * This notification is triggered when the SDK requests an access token to ask
 * the server for a certificate. The app should query the server for a token and
 * return it here, synchronously. This access token will be propagated to the
 * HypeLabs certification server for validation, along with the user identifier
 * and the app identifier. The server will forward the request to whatever is
 * configured on the HypeLabs dashboard for this app. In case the server validates
 * the access token, a certificate will be installed on the device. The process
 * will be repeated when the certificate expires, requiring access to the Internet
 * again. If the token is not properly validated or no certificate can be generated,
 * Hype will refuse to start. This method is called when no certificate exists or
 * an existing one is about to expire, and only when the SDK is requested to start.
 * This method is not called if a valid certificate is already installed on the device.
 * This method is called for each observer subscribed for state events, but the
 * implementation uses the first non-null response from any of the observers. After
 * that, no other observers will be called.
 * @param userIdentifier The user identifier to validate.
 * @returns An access token to validate with the backend.
 */
- (NSString *)hypeDidRequestAccessTokenWithUserIdentifier:(NSUInteger)userIdentifier;

@optional

/**
 * This notification is issued whenever the Hype instance changes state. This
 * method could be used as an alternative to `-hypeDidStart:` and `-hypeDidStop:error:`,
 * as it indicates when Hype enters into `HYPStateRunning` and `HYPStateIdle`
 * states, but also `HYPStateStarting` and `HYPStateStopping`. Whether to use
 * this method or the other specific notifications is a design call, as both
 * types of notification are guaranteed to always be triggered when state changes
 * occur. However, the more specific `-hypeDidStart:` and `-hypeDidStop:error:`
 * are preferable. Notice, for instance, that this method does not provide error
 * information in case of stoppage.
 */
- (void)hypeDidChangeState;

@end

