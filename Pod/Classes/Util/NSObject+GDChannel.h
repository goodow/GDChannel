//
// Created by Larry Tin on 15/9/24.
//

#import <Foundation/Foundation.h>
#import "GDCMessageHandler.h"
#import "GDCBus.h"

@interface NSObject (GDChannel) <GDCMessageHandler>

@property(nonatomic, readonly) id <GDCBus> bus;

@end