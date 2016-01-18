//
// Created by Larry Tin on 15/4/30.
//

#import <UIKit/UIKit.h>
#import "GDCMessage.h"
#import "NSObject+GDChannel.h"

/* @deprecated */
// UIInterfaceOrientation
static NSString *const optionStatusBarOrientation = @"_statusBarOrientation";

@interface GDCViewControllerHelper : NSObject

+ (UIViewController *)topViewController;

+ (UIViewController *)backViewController;

+ (void)show:(UIViewController *)controller message:(id <GDCMessage>)message;

+ (void)config:(UIViewController *)controller viewOptions:(GDCViewOptions *)viewOptions;

+ (UIViewController *)findViewController:(Class)viewControllerClass;

+ (void)aspect_hookSelector;
@end