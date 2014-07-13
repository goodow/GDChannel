// Copyright 2014 Goodow.com. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
//  GDCMessage.h
//  GDChannel
//
//  Created by Larry Tin.
//

#import "GDCBus.h"

/**
 * Represents a message on the event bus.
 */
@protocol GDCMessage

/**
 * The body of the message
 */
- (id)body;

/**
 * Whether this message originated in the local session.
 */
- (BOOL)isLocal;

/**
 * Signal that processing of this message failed. If the message was sent specifying a result handler
 * the handler will be called with a failure corresponding to the failure code and message specified here
 * @param failureCode A failure code to pass back to the sender
 * @param msg A message to pass back to the sender
 */
- (void)fail:(int)failureCode message:(NSString *)msg;

/**
 * Reply to this message. If the message was sent specifying a reply handler, that handler will be
 * called when it has received a reply. If the message wasn't sent specifying a receipt handler
 * this method does nothing.
 */
- (void)reply:(id)msg;

/**
 * The same as {@code reply:(id)msg)} but you can specify handler for the reply - i.e.
 * to receive the reply to the reply.
 */
- (void)reply:(id)msg replyHandler:(GDCMessageHandler)replyHandler;

/**
 * The reply topic (if any)
 */
- (NSString *)replyTopic;

/**
* The topic the message was sent to
*/
- (NSString *)topic;

@end
