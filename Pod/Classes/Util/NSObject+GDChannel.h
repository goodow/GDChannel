//
// Created by Larry Tin on 15/9/24.
//

#import <Foundation/Foundation.h>
#import "GDCMessageHandler.h"
#import "GDCBus.h"

@interface NSObject (GDChannel) <GDCMessageHandler>

- (id <GDCBus>)bus;

@end