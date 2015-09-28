//
// Created by Larry Tin on 15/4/30.
//

#import <UIKit/UIKit.h>
#import "GDCMessage.h"

static NSString *const optionDisplay = @"_display";
static NSString *const optionRedirect = @"_redirect";
static NSString *const optionEdgesForExtendedLayout = @"_edge";
static NSString *const optionHidesBottomBarWhenPushed = @"_hidesBottomBarWhenPushed";
static NSString *const optionNavBar = @"_navBar";
static NSString *const optionToolBar = @"_toolBar";
static NSString *const optionTabBar = @"_tabBar";
static NSString *const optionDeviceOrientation = @"_deviceOrientation";
static NSString *const optionAttemptRotationToDeviceOrientation = @"_attemptRotationToDeviceOrientation";
// @deprecated
static NSString *const optionStatusBarOrientation = @"_statusBarOrientation";

@interface GDCViewControllerHelper : NSObject

+ (UIViewController *)topViewController;

+ (UIViewController *)backViewController;

+ (void)show:(UIViewController *)controller message:(id <GDCMessage>)message;

+ (UIViewController *)findViewController:(Class)viewControllerClass;

@end