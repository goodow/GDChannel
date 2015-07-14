//
// Created by Larry Tin on 15/4/30.
//

#import <UIKit/UIKit.h>
#import "GDCViewControllerHelper.h"
#import "GDCMessage.h"
#import "UIViewController+GDChannel.h"

@implementation GDCViewControllerHelper

+ (UIViewController *)topViewController {
  return [self findTopViewController:UIApplication.sharedApplication.keyWindow.rootViewController];
}

+ (void)show:(UIViewController *)controller message:(id <GDCMessage>)message {
  id payload = message.payload;
  BOOL isPayloadDict = [payload isKindOfClass:NSDictionary.class];
  if (isPayloadDict && payload[@"_redirect"] && ![payload[@"_redirect"] boolValue]) {
    [controller receivedWithMessage:message];
    return;
  }
  BOOL found = [self find:controller in:UIApplication.sharedApplication.keyWindow.rootViewController];
  if (found) {
    [self config:controller message:message];
    void (^block)() = ^{
        UIViewController *current = controller;
        while (current.parentViewController) {
          if ([current.parentViewController isKindOfClass:UITabBarController.class]) {
            ((UITabBarController *) current.parentViewController).selectedViewController = current;
          } else if ([current.parentViewController isKindOfClass:UINavigationController.class]) {
            [((UINavigationController *) current.parentViewController) popToViewController:current animated:YES];
          }
          current = current.parentViewController;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [controller receivedWithMessage:message];
        });
    };
    if (controller.presentedViewController) {
      [controller dismissViewControllerAnimated:YES completion:block];
    } else {
      block();
    }
    return;
  }

  UIViewController *top = self.topViewController;
  if (isPayloadDict) {
    if (payload[@"_edge"]) {
      controller.edgesForExtendedLayout = [payload[@"_edge"] intValue];
    }
    if (payload[@"_hidesBottomBarWhenPushed"]) {
      controller.hidesBottomBarWhenPushed = [payload[@"_hidesBottomBarWhenPushed"] boolValue];
    }
  }
  if (top.navigationController) {
    [top.navigationController pushViewController:controller animated:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self config:controller message:message];
        [controller view]; // force viewDidLoad to be called
        [controller receivedWithMessage:message];
    });
    return;
  }

  [top presentViewController:[[UINavigationController alloc] initWithRootViewController:controller] animated:YES completion:^{
      [self config:controller message:message];
      [controller receivedWithMessage:message];
  }];
}

+ (UIViewController *)findTopViewController:(UIViewController *)parent {
  if (parent.presentedViewController) {
    return [self findTopViewController:parent.presentedViewController];
  }
  if ([parent isKindOfClass:UITabBarController.class]) {
    return [self findTopViewController:((UITabBarController *) parent).selectedViewController];
  }
  if ([parent isKindOfClass:UINavigationController.class]) {
    return [self findTopViewController:((UINavigationController *) parent).visibleViewController];
  }
  return parent;
}

+ (void)config:(UIViewController *)controller message:(id <GDCMessage>)message {
  if (![message.payload isKindOfClass:NSDictionary.class]) {
    return;
  }
  NSDictionary *payload = message.payload;
  if (payload[@"_navBar"]) {
    [controller.navigationController setNavigationBarHidden:![payload[@"_navBar"] boolValue] animated:NO];
  }
  if (payload[@"_toolBar"]) {
    [controller.navigationController setToolbarHidden:![payload[@"_toolBar"] boolValue] animated:NO];
  }
  if (payload[@"_tabBar"]) {
    controller.tabBarController.tabBar.hidden = ![payload[@"_tabBar"] boolValue];
  }
}

+ (BOOL)find:(UIViewController *)controller in:(UIViewController *)parent {
  if (parent.presentedViewController) {
    BOOL found = [self find:controller in:parent.presentedViewController];
    if (found) {
      return YES;
    }
  }
  if ([parent isKindOfClass:UITabBarController.class]) {
    UITabBarController *tabBarController = (UITabBarController *) parent;
    if ([tabBarController.viewControllers containsObject:controller]) {
      return YES;
    }
    for (UIViewController *ctr in tabBarController.viewControllers) {
      BOOL found = [self find:controller in:ctr];
      if (found) {
        return YES;
      }
    }
  }
  if ([parent isKindOfClass:UINavigationController.class]) {
    UINavigationController *navigationController = (UINavigationController *) parent;
    if ([navigationController.viewControllers containsObject:controller]) {
      return YES;
    }
    for (UIViewController *ctr in navigationController.viewControllers.reverseObjectEnumerator) {
      BOOL found = [self find:controller in:ctr];
      if (found) {
        return YES;
      }
    }
  }
  return controller == parent;
}

@end