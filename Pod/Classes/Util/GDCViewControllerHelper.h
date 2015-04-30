//
// Created by Larry Tin on 15/4/30.
//

#import <Foundation/Foundation.h>

@protocol GDCMessage;

@interface GDCViewControllerHelper : NSObject

+ (UIViewController *)topViewController;

+ (void)show:(UIViewController *)controller message:(id <GDCMessage>)message;

+ (UIViewController *)findTopViewController:(UIViewController *)parent;

@end