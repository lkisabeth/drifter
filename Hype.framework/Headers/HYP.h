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

#import <Hype/HYPMessageObserver.h>
#import <Hype/HYPNetworkObserver.h>
#import <Hype/HYPStateObserver.h>
#import <Hype/HYPTransportType.h>
#import <Hype/HYPInstance.h>
#import <Hype/HYPMessage.h>

/**
 * This constant is the default user identifier used by Hype when no identifier
 * is set. When an instance is found on the network, the app should compare the
 * instance's user identifier with this one for equality before making assumptions
 * of validity.
 */
FOUNDATION_EXPORT const NSUInteger HYPDefaultUserIdentifier;

/**
 * This enumeration list states Hype can be in. The state the framework is
 * in indicates what activities it's performing and what events are to be
 * expected. The state can be queried with the `+ state` method.
 */
typedef NS_ENUM(NSUInteger, HYPState)
{
    /**
     * This state indicates that the SDK is idle. This means that Hype is not
     * publishing the device on the network nor browsing for other devices
     * being published. Initially, the device is not participating on the
     * network, nor is it expected to be so until Hype is explicitly requested
     * to start. This state is not expected to change until that happens.
     * However, if the SDK has previously been started and instances have
     * been found, Hype can get back to this state if requested to stop. In
     * that case, no new instances are found on direct link, but they may
     * still be found in mesh. Communicating with previously found instances
     * is still possible, unless they are lost.
     */
    HYPStateIdle = 0,
    
    /**
     * This state indicates that the SDK is starting. This occurs after Hype
     * being requested to start and while the request is still being processed.
     * This state changes as soon as Hype is either actively publishing the
     * device on the network or actively browsing for other devices, whichever
     * occurs first. Instances cannot be found on direct link at this point.
     */
    HYPStateStarting = 1,
    
    /**
     * This state indicates that the SDK is running. This means that it is
     * actively participating on the network, meaning that it could be
     * advertising itself, scanning for other devices in direct link, or
     * both. Hype is considered to be running if at least one of its
     * transport types is as well. If activity is not requested on the
     * framework (such as stopping) this state will change only if external
     * factors trigger a change in the adapter's state, such as the user
     * turning the adapter off, which will cause the framework to halt and
     * become idle with an error.
     */
    HYPStateRunning = 2,
    
    /**
     * This state indicates that the SDK is stopping. This means that Hype is
     * actively participating on the network, and the process to stop doing so
     * has already begun but has yet not been completed. This means that at
     * least one of the transports is still stopping, although others might
     * have already done so. This state changes as soon as all of the SDK's
     * transports have stopped.
     */
    HYPStateStopping = 3
};

/**
 * This class is the main entry point for the Hype SDK. It provides facade
 * access to the Hype service running on the background. This class wraps
 * the instance created for the host device. Each app can only create a
 * single instance, which is why class is a singleton and uses class methods.
 * This class allows users of the SDK to listen to events on the created
 * instance by subscribing observers, as well as starting and stopping
 * the Hype services.
 */
@interface HYP : NSObject

/**
 * This method returns the SDK's current state, indicating what kind of
 * activity it's performing at any given moment.
 * @see HYPState
 */
+ (HYPState)state;

/**
 * This method returns the HYPInstance object associated with the instance
 * created on the host device. This property is nil until the Hype framework
 * is first requested to start. This object is then kept throughout the
 * framework's lifecycle.
 * @return The Hype instance associated with the host device.
 */
+ (HYPInstance *)hostInstance;

/**
 * This method gives the developer control over which transports are to be
 * enabled and used for network discovery and communications. The SDK attempts
 * to start transports specified here, but only if the transport is enabled
 * by the system as well. The method's sole argument, transportType, consists
 * of a bitwise-OR enumeration of transport types, selected out of available
 * types listed under HYPTransportType. All transports listed there are available
 * for all Apple platforms, except HYPTransportTypeWeb. For example, specifying
 * `HYPTransportTypeBluetoothLowEnergy | HYPTransportTypeWiFiInfra` sets both
 * Bluetooth Low Energy and Infrastructure Wi-Fi to start when Hype starts.
 * Notice, however, that some of the transports work in bundles. On all Apple
 * platforms, Bluetooth Classic, Infrastructure Wi-Fi, and Wi-Fi Direct
 * (peer-to-peer Wi-Fi) use Bonjour to function and as such they cannot be
 * started individually; requesting one of them to start triggers the others
 * to start as well. These three transports must either all run or none,
 * unless disabled by the user or operating system. By default, Hype starts
 * all transports (HYPTransportTypeAll).
 * @param transportType Bitwise OR enumeration of transports to enable.
 */
+ (void)setTransportType:(HYPTransportType)transportType;

/**
 * User identifiers can optionally be assigned to identify the user running
 * the app. This identifier is passed on the network when instances are found,
 * even before they are resolved. This makes user identifiers useful to help
 * deciding whether to resolve an instance, instead of having the app blindly
 * resolve all instances found, saving network overhead. This identifier can
 * be used, for example, to query a database of contacts and fetch user
 * information, if available. After determining whether the contact is
 * interesting, the app should resolve the instance. User identifiers can
 * be any value between 0 and 2.147.483.647 (the equivalent of 2 raised
 * to a power of 31, minus one). If not set, Hype uses the default user
 * identifier `HYPDefaultUserIdentifier`. When instances are found on the
 * network, the app should check the identifier against this constant before
 * assuming it to be a valid identifier.
 * @param userIdentifier The user identifier to set.
 */
+ (void)setUserIdentifier:(NSUInteger)userIdentifier;

/**
 * This method sets the mandatory app identifier, used for matching purposes
 * on the network. App identifiers must be generated on HypeLabs' dashboard,
 * after logging in, under the Apps tab. These identifiers are represented
 * by strings with 8 hexadecimal digits. If the format is not valid, the SDK
 * throws an exception. Hype does not use an identifier by default, making
 * calling this method mandatory before starting the SDK. The general app
 * identifier `00000000` can be used for testing purposes, but is not suitable
 * for deployment, and should be replaced by a proper one.
 * @param appIdentifier The app identifier to set.
 */
+ (void)setAppIdentifier:(NSString *)appIdentifier;

/**
 * An announcement is an abstract data space that is exchanged at handshake
 * time. This space is reserved for the app, so that it can participate on
 * the handshake process, when two instances first start communicating. The
 * SDK is oblivious to the contents passed on an announcement, but it
 * optimizes its delivery by caching it on the network. The motivation comes
 * from the observation that, when two instances find each other, developers
 * often start by exchanging a message to identify users running the app,
 * such as user names. Because announcements are cached, they imposed less
 * overhead, and thus are preferable to the alternative, especially in multi-hop
 * scenarios. Still, announcements are very limited. At most, they can be
 * 255 bytes long, a limit that is expected to grow in future versions. This
 * data is exchanged during the handshake process, meaning that the two
 * instances have not exchanged cryptography keys yet, meaning that the data
 * is not encrypted.
 * @param announcement The announcement data to set.
 */
+ (void)setAnnouncement:(NSData *)announcement;

/**
 * Adds a message observer. After being added, the observer will get notifications
 * for message states. Notifications will be triggered when messages are received,
 * when they fail delivery, or when a message is delivered. If the observer has
 * previously already been registered, it will not be registered twice, and the
 * method will do nothing.
 * @param messageObserver The message observer (HYPMessageObserver) to add.
 */
+ (void)addMessageObserver:(id<HYPMessageObserver>)messageObserver;

/**
 * This method removes a message observer (HYPMessageObserver) that was previously
 * registered with `-addHypeMessageObserver:`. If the observer was not previously
 * registered or has already been removed, this method does nothing. After being
 * removed, the observer will no longer get any notifications from the SDK.
 * @param messageObserver The message observer (HPYMessageObserver) to remove.
 */
+ (void)removeMessageObserver:(id<HYPMessageObserver>)messageObserver;

/**
 * Adds a network observer. Network observers get notifications for network events,
 * such as instances being found and lost on the network. The network observer
 * (HYPNetworkObserver) being added will get notifications after a call to this
 * method. If the observer has already been registered, this method does nothing,
 * and the observer will not get duplicated events.
 * @param networkObserver The network observer (HYPNetworkObserver) to add.
 */
+ (void)addNetworkObserver:(id<HYPNetworkObserver>)networkObserver;

/**
 * This method removes a previously registered network observer (HYPNetworkObserver).
 * If the observer has not been registered or has already been removed, this method
 * does nothing. After being removed, the observer will no longer get notifications
 * from the SDK.
 * @param networkObserver The network observer (HYPNetworkObserver) to remove.
 */
+ (void)removeNetworkObserver:(id<HYPNetworkObserver>)networkObserver;

/**
 * Adds a state observer. State observers get notifications for Hype's state and
 * lifecycle events. If the observer has already been registered it will not be
 * registered twice, preventing the observer from getting duplicate notifications.
 * @param stateObserver The state observer (HYPStateObserver) to register.
 */
+ (void)addStateObserver:(id<HYPStateObserver>)stateObserver;

/**
 * This method removes a previously registered state observer (HYPStateObserver).
 * If the observer is not present on the registry, because it was not added or
 * because it has already been removed, this method does nothing. After being
 * removed, the observer will no longer get notifications from the SDK.
 * @param stateObserver The state observer (HYPStateObserver) to remove.
 */
+ (void)removeStateObserver:(id<HYPStateObserver>)stateObserver;

/**
 * Requests Hype to resolve a given instance. Resolving an instance forces the
 * handshake to be performed between the two of them, meaning it's a mandatory
 * step before engaging in communications. Only instances found in mesh need
 * to be resolved, so those found in direct link need not. This means that this
 * method needs only be called on those instances; however, resolving an instance
 * that has already been resolved results in a call to `- hype:didResolveInstance:`,
 * so in practical terms there's no real different and it's always OK to call
 * this method. Sending a message to an instance that hasn't been resolved yet
 * results in a failed notification, to the method `- hype:didFailSendingMessage:toInstance:error:`.
 * The instance must have previously been found and not lost, or otherwise calling
 * this method results in a delegate call to `- hype:didFailResolvingInstance:error:`.
 * @param instance The instance to resolve.
 */
+ (void)resolveInstance:(HYPInstance *)instance;

/**
 * Calling this method requests the framework to start its services, by publishing
 * itself on the network and browsing for other devices. In case of success, network
 * observers will get a `-hypeDidStart:` notification, indicating that the device
 * is somehow participating on the network. This might not mean that the device is
 * both advertising and scanning, but that it is participating in either or both
 * ways. In case of failure, the observers get a `-hypeDidFailStarting:error:`
 * notification. This is common if all adapters are off, for example. At that
 * point, it's useless trying to start Hype again. Instead, the implementation
 * should wait for an observer notification indicating that recovery is possible,
 * with `-hypeDidBecomeReady:`. If the services have already been requested to
 * run but have not succeeded nor failed (that is, the request is still being
 * processed) this method does nothing. If the services are already running,
 * the observers get an immediate notification indicating that the services
 * have started as if they just did, with `-hypeDidStart:`. All options must
 * be set before this method is called.
 */
+ (void)start;

/**
 * Calling this method requests the framework to stop its services by no longer
 * publishing itself on the network nor browsing for other instances. This does
 * not imply previously found instances to be lost; ongoing operations should
 * continue and communicating with known instances should be possible, but the
 * framework will no longer find or be found by other instances on direct link.
 * However, instances may still be found in mesh.
 */
+ (void)stop;

/**
 * This method attempts to send a message to a given instance. The instance must
 * be a previously found and not lost instance, or else this method fails with an
 + error. It returns immediately (non blocking), queues the data to be sent, and
 * returns the message (`HYPMessage`) that was created for wrapping the data. That
 * data structure is helpful for tracking the progress of messages as they are being
 * sent over the network. The message or the data are not strongly kept by the
 * framework. The data is copied and kept while it's queued, but the memory is
 * released as its fragments are sent. If the data is needed for later use, it
 * should be kept at this point, or otherwise it won't be recoverable. Messages
 * contain an identifier which can later be used to match events with the original
 * data. Progress notifications are issued to message observers, `HYPMessageObserver`.
 * When listening to progress tracking notifications, two concepts are important
 * to distinguish: sending and delivering. A message being sent is indicated by
 * `-hype:didSendMessage:toInstance:progress:complete:`, and means that the data
 * was buffered, but has not necessarily arrived to its destination. Delivery of
 * the message is indicated by `-hype:didDeliverMessage:toInstance:progress:complete:`
 * on the other hand, which in turn means that the content has reached its destination
 * and that has been acknowledged by the receiving instance. This distinction is
 * especially important in mesh, when the proxy device may not be the same as the
 * one the data is intended to. The `trackProgress` argument indicates whether to
 * track delivery. The data being queued to the output stream (sent) is always
 * notified, regardless of that setting. Notice that passing `YES` to this parameter
 * incurs extra overhead on the network, as it implies acknowledgements from the
 * destination back to the origin. If progress tracking is not needed, this should
 * always be set to `NO`. In case an error occurs that prevents the message from
 * reaching the destination, the delegate gets a failure notification through
 * `-hype:didFailSendingMessage:toInstance:error:` with an appropriate error message
 * describing the reasons. If a proper reason cannot be determined, a probable one
 * is used instead.
 * @param data The data to be sent.
 * @param toInstance The destination instance.
 * @param trackProgress Whether to track delivery progress.
 * @return A message wrapper containing some metadata.
 */
+ (HYPMessage *)sendData:(NSData *)data
              toInstance:(HYPInstance *)toInstance
           trackProgress:(BOOL)trackProgress;

/**
 * This method calls `+ sendData:toInstance:trackProgress:` with the progress
 * tracking option set to `NO`. All other technicalities described for that
 * method also apply.
 * @param data The data to send.
 * @param toInstance The instance to send the data to.
 * @return A message wrapper containing some metadata.
 */
+ (HYPMessage *)sendData:(NSData *)data
              toInstance:(HYPInstance *)toInstance;

@end
