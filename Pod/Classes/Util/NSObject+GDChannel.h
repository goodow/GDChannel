//
// Created by Larry Tin on 15/9/24.
//

#import <Foundation/Foundation.h>
#import "GDCMessageHandler.h"
#import "GDCBus.h"

static const char *_GDCViewOptionsAssociatedKey = "_GDCViewOptionsAssociatedKey";

@interface NSObject (GDChannel) <GDCMessageHandler>

@property(nonatomic, readonly) id <GDCBus> bus;

@end

@interface UIViewController (GDChannel)

@property(nonatomic, readonly) GDCViewOptions *viewOptions;

@end