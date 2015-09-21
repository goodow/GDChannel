//
// Created by Larry Tin on 15/4/30.
//

#import <Foundation/Foundation.h>
#import "GDCMessage.h"

@interface GDCViewControllerHelper : NSObject

+ (UIViewController *)topViewController;

+ (UIViewController *)backViewController;

+ (void)show:(UIViewController *)controller message:(id <GDCMessage>)message;

+ (UIViewController *)findViewController:(Class)viewControllerClass;

@end