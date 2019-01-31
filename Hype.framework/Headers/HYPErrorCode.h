// 
// Copyright (C) 2018 Hype Labs - All Rights Reserved
// 
// NOTICE: All information contained herein is, and remains the property of
// Hype Labs. The intellectual and technical concepts contained herein are
// proprietary to Hype Labs and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret and copyright law.
// Dissemination of this information or reproduction of this material is
// strictly forbidden unless prior written permission is obtained from
// Hype Labs.
// 
// DISCLAIMER: This file is automatically (re)generated during the build
// process. Any changes made to it will be overwritten.
// 

#ifndef HYP_ERROR_CODE_H_INCLUDED_
#define HYP_ERROR_CODE_H_INCLUDED_

#include <Foundation/Foundation.h>

/**
 * Lists and documents errors and their respective codes. The error descriptions
 * indicate what went wrong in a way that is commonly perceptible, but they may
 * not suitable for displaying to the end user. Errors indicate something that
 * went wrong during runtime, and that most likely could not be prevented by the
 * developer. Preventable issues, such as bad API usage, is flagged with
 * exceptions instead. The error codes can be used for helping with the cause of
 * an issue, as they identify the underlying cause. They are also helpful when
 * seeking support.
 */
typedef NS_ENUM(NSUInteger, HYPErrorCode) {

	/**
	 * An unknown error occurred. There are no details about the cause because the
	 * cause could not be determined. This error should never occur, and is reserved
	 * for abnormal circumstances.
	 */
	HYPErrorCodeUnknown = 42951,

	/**
	 * An operation could not be completed because the adapter is disabled.
	 * Implementations must not attempt to turn it on, and instead recommend the user
	 * to do so through recovery suggestions. When applicable, implementations should
	 * subscribe to adapter state changes and attempt recovery when the adapter is
	 * known to be on, after asking a delegate whether they should.
	 */
	HYPErrorCodeAdapterDisabled = 36705,

	/**
	 * An operation could not be completed because adapter activity has not been
	 * authorized by the user and the operating system is denying permission. Recovery
	 * suggestions should advise the user to authorize activity on the adapter.
	 */
	HYPErrorCodeAdapterUnauthorized = 47354,

	/**
	 * The implementation is requesting activity on an adapter that is not supported
	 * by the current platform. Recovery is not possible. Recovery suggestions should
	 * recommend the user to update their systems or contact the manufacturer.
	 */
	HYPErrorCodeAdapterNotSupported = 166,

	/**
	 * An operation cannot be completed because the adapter is busy doing something
	 * else or the implementation is not allowing it to overlap with other ongoing
	 * activities. The operation will not be scheduled for later, and is considered to
	 * have failed.
	 */
	HYPErrorCodeAdapterBusy = 53583,

	/**
	 * A remote peer failed to comply with a protocolar specification and the
	 * implementation is rejecting to communicate with it. This probably indicates an
	 * attacker on the network attempting to break through Hype's protocols. The SDK
	 * will reject communicating with the peer by blacklisting it.
	 */
	HYPErrorCodeProtocolViolation = 42883,

	/**
	 * An operation has failed due to a connection not having previously been
	 * established. The implementation should first attempt to connect. The operation
	 * will not attempt to resume and instead must be manually retried.
	 */
	HYPErrorCodeNotConnected = 37818,

	/**
	 * A connection request has failed because the peer is not connectable.
	 * Implementations should not reattempt to connect. The operation will not attempt
	 * to resume and instead must be manually retried.
	 */
	HYPErrorCodeNotConnectable = 38743,

	/**
	 * An operation failed because the connection timed out. Implementations should
	 * attempt to reconnect before proceeding. The operation will not attempt to
	 * resume and instead must be manually retried.
	 */
	HYPErrorCodeConnectionTimeout = 37809,

	/**
	 * An operation failed because the stream is not open. The implementation should
	 * first attempt to open it.
	 */
	HYPErrorCodeStreamNotOpen = 53460,

	/**
	 * A certificate is required to communicate offline, but that requires a one-time
	 * Internet connection. Make sure the Internet is reachable on the device. After
	 * the certificate is installed an Internet connection will not be required until
	 * it expires.
	 */
	HYPErrorCodeCertificateNotFound = 61627,

	/**
	 * The current certificate has expired and must be renewed. Doing so failed due to
	 * lack of Internet connectivity. Check your connection.
	 */
	HYPErrorCodeCertificateExpired = 24212,

	/**
	 * A instance triggers this kind of error when a resolve request fails. Instances
	 * must be reachable to be resolved.
	 */
	HYPErrorCodeInstanceFailResolving = 64503,

};

#endif /* HYP_ERROR_CODE_H_INCLUDED_ */

