//
// Created by Larry Tin on 15/12/9.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GDCEntry.h"

@interface GDCViewOptions : GDCEntry

// {push, present, presentWithoutNav}
@property(nonatomic, strong) NSString *display;
// 界面是否跳转
@property(nonatomic) BOOL redirect;

@property(nonatomic) UIRectEdge edgesForExtendedLayout;

@property(nonatomic) BOOL hidesBottomBarWhenPushed;
// 是否显示NavigationBar
@property(nonatomic) BOOL navBar;
// 是否显示Toolbar
@property(nonatomic) BOOL toolBar;
// 是否显示tabBar
@property(nonatomic) BOOL tabBar;
// 是否显示statusBar
@property(nonatomic) BOOL statusBar;

@property(nonatomic) UIStatusBarStyle statusBarStyle;
// 更改设备的朝向
@property(nonatomic) UIDeviceOrientation deviceOrientation;
@property(nonatomic) BOOL attemptRotationToDeviceOrientation;
@property(nonatomic) BOOL autorotate;
@property(nonatomic) UIInterfaceOrientationMask supportedInterfaceOrientations;
@property(nonatomic) UIInterfaceOrientation preferredInterfaceOrientationForPresentation;

/* present 显示时的动画 */
@property(nonatomic) id <UIViewControllerTransitioningDelegate> transition;
@property(nonatomic) UIModalPresentationStyle modalPresentationStyle;
@property(nonatomic) UIModalTransitionStyle modalTransitionStyle;

@end