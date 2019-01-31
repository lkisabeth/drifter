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
#import "HYPErrorCode.h"

/**
 * This class works as a container for error information. This class is
 * extensively used by the SDK, especially in delegates. It holds four
 * main properties: a code, a description, a reason for the error, and
 * a recovery suggestion. Error codes are listed under `HYPErrorCode`,
 * along with their meaning. The description indicates what went wrong,
 * such as "Couldn't send a message". The reason indicates the cause, such
 * as "Bluetooth is not turned on". Continuing on the same example, the
 * recovery suggestion indicates a possible recovery from the error, such
 * as "Try turning Bluetooth on".
 */
@interface HYPError : NSObject

/**
 * This property indicates the error code, as listed by the `HYPErrorCode`
 * enumeration.
 */
@property (atomic, readonly) HYPErrorCode code;

/**
 * This property provides a description of the error, indicating what
 * went wrong. An example could be "Could not send a message".
 */
@property (atomic, readonly) NSString * description;

/**
 * This property gives a reason for the failure. An example could be
 * "The Bluetooth adapter is turned off".
 */
@property (atomic, readonly) NSString * reason;

/**
 * This property provides a recovery suggestion that could help in fixing
 * the problem that caused the error. An example could be "Try turning
 * Bluetooth on".
 */
@property (atomic, readonly) NSString * suggestion;

/**
 * Initializes a HYPError instance.
 * @param code The error code.
 * @param description An error description.
 * @param reason A cause for the error.
 * @param suggestion A recovery suggestion.
 */
- (instancetype)initWithCode:(HYPErrorCode)code
                 description:(NSString *)description
                      reason:(NSString *)reason
                  suggestion:(NSString *)suggestion;

@end

