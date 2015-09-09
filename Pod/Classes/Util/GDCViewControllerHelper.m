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
  UIViewController *found = [self find:controller in:UIApplication.sharedApplication.keyWindow.rootViewController instanceOrClass:YES];
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
      controller.edgesForExtendedLayout = (UIRectEdge) [payload[@"_edge"] intValue];
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

+ (UIViewController *)findViewController:(Class)viewControllerClass {
  return [self find:(id) viewControllerClass in:UIApplication.sharedApplication.keyWindow.rootViewController instanceOrClass:NO];
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

+ (UIViewController *)find:(id)controllerOrClass in:(UIViewController *)parent instanceOrClass:(BOOL)isInstance {
  if (parent.presentedViewController) {
    UIViewController *found = [self find:controllerOrClass in:parent.presentedViewController instanceOrClass:isInstance];
    if (found) {
      return found;
    }
  }
  if ([parent isKindOfClass:UITabBarController.class]) {
    UITabBarController *tabBarController = (UITabBarController *) parent;
//    if ([tabBarController.viewControllers containsObject:controllerOrClass]) {
//      return controllerOrClass;
//    }
    for (UIViewController *ctr in tabBarController.viewControllers) {
      UIViewController *found = [self find:controllerOrClass in:ctr instanceOrClass:isInstance];
      if (found) {
        return found;
      }
    }
  }
  if ([parent isKindOfClass:UINavigationController.class]) {
    UINavigationController *navigationController = (UINavigationController *) parent;
//    if ([navigationController.viewControllers containsObject:controllerOrClass]) {
//      return controllerOrClass;
//    }
    for (UIViewController *ctr in navigationController.viewControllers.reverseObjectEnumerator) {
      UIViewController *found = [self find:controllerOrClass in:ctr instanceOrClass:isInstance];
      if (found) {
        return found;
      }
    }
  }
  return isInstance ? (controllerOrClass == parent ? parent : nil) : ([parent isKindOfClass:controllerOrClass] ? parent : nil);
}

@end