//
// Created by Larry Tin on 15/9/24.
//

#import <Foundation/Foundation.h>
#import "GDCMessageHandler.h"
#import "GDCBus.h"

static const char *_GDCMessageAssociatedKey = "_GDCMessageAssociatedKey";

@interface NSObject (GDChannel) <GDCMessageHandler>

@property(nonatomic, readonly) id <GDCBus> bus;
@property(nonatomic, readonly) id <GDCMessage> message;

@end