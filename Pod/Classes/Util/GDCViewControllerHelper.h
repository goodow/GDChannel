//
// Created by Larry Tin on 15/4/30.
//

#import <UIKit/UIKit.h>
#import "GDCMessage.h"
#import "NSObject+GDChannel.h"

// 值类型: NSString, {push, present, presentWithoutNav}
static NSString *const optionDisplay = @"_display";
// 值类型: BOOL, 界面是否跳转
static NSString *const optionRedirect = @"_redirect";
// 值类型: UIRectEdge
static NSString *const optionEdgesForExtendedLayout = @"_edge";
// 值类型: BOOL
static NSString *const optionHidesBottomBarWhenPushed = @"_hidesBottomBarWhenPushed";
// 值类型: BOOL, 是否显示NavigationBar
static NSString *const optionNavBar = @"_navBar";
// 值类型: BOOL, 是否显示Toolbar
static NSString *const optionToolBar = @"_toolBar";
// 值类型: BOOL, 是否显示tabBar
static NSString *const optionTabBar = @"_tabBar";
// 值类型: BOOL, 是否显示statusBar
static NSString *const optionStatusBar = @"_statusBar";
// 值类型: UIStatusBarStyle
static NSString *const optionStatusBarStyle = @"_statusBarStyle";
// 值类型: UIDeviceOrientation, 更改设备的朝向
static NSString *const optionDeviceOrientation = @"_deviceOrientation";
// 值类型: BOOL
static NSString *const optionAttemptRotationToDeviceOrientation = @"_attemptRotationToDeviceOrientation";
// 值类型: BOOL
static NSString *const optionAutorotate = @"_autorotate";
// 值类型: UIInterfaceOrientationMask
static NSString *const optionSupportedInterfaceOrientations = @"_supportedInterfaceOrientations";
// 值类型: UIInterfaceOrientation
static NSString *const optionPreferredInterfaceOrientationForPresentation = @"_preferredInterfaceOrientationForPresentation";

/* present 显示时的动画 */
// 值类型: id <UIViewControllerTransitioningDelegate>
static NSString *const optionTransition = @"_transition";
// 值类型: UIModalPresentationStyle
static NSString *const optionModalPresentationStyle = @"_modalPresentationStyle";
// 值类型: UIModalTransitionStyle
static NSString *const optionModalTransitionStyle = @"_modalTransitionStyle";

/* @deprecated */
// UIInterfaceOrientation
static NSString *const optionStatusBarOrientation = @"_statusBarOrientation";

@interface GDCViewControllerHelper : NSObject

+ (UIViewController *)topViewController;

+ (UIViewController *)backViewController;

+ (void)show:(UIViewController *)controller message:(id <GDCMessage>)message;

+ (UIViewController *)findViewController:(Class)viewControllerClass;

+ (void)aspect_hookSelector;
@end