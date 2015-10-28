//
// Created by Larry Tin on 15/4/30.
//

#import "GDCViewControllerHelper.h"
#import "UIViewController+GDChannel.h"

@implementation GDCViewControllerHelper

+ (UIViewController *)topViewController {
  return [self findTopViewController:UIApplication.sharedApplication.keyWindow.rootViewController];
}

+ (UIViewController *)backViewController {
  UIViewController *top = GDCViewControllerHelper.topViewController;
  NSArray *navViewControllers = top.navigationController.viewControllers;
  if (navViewControllers.count > 1) {
    return navViewControllers[navViewControllers.count - 2];
  } else if (top.presentingViewController) {
    return top.presentingViewController;
  }
  return nil;
}

+ (void)show:(UIViewController *)controller message:(id <GDCMessage>)message {
  if (!controller) {
    return;
  }
  NSDictionary *options = message.options;
  if (options[optionRedirect] && ![options[optionRedirect] boolValue]) {
    [controller handleMessage:message];
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
            [controller handleMessage:message];
        });
    };
    if (controller.presentedViewController) {
      [controller dismissViewControllerAnimated:YES completion:block];
    } else {
      block();
    }
    return;
  }

  BOOL forcePresent = NO, forcePresentWithoutNav = NO;
  if (options) {
    if (options[optionEdgesForExtendedLayout]) {
      controller.edgesForExtendedLayout = (UIRectEdge) [options[optionEdgesForExtendedLayout] intValue];
    }
    if (options[optionHidesBottomBarWhenPushed]) {
      controller.hidesBottomBarWhenPushed = [options[optionHidesBottomBarWhenPushed] boolValue];
    }
    NSString *display = options[optionDisplay];
    if ([display isEqualToString:@"present"]) {
      forcePresent = YES;
    } else if ([display isEqualToString:@"presentWithoutNav"]) {
      forcePresentWithoutNav = forcePresent = YES;
    }

    if (forcePresent) {
      // 动画: 仅在 present 时有效
      id <UIViewControllerTransitioningDelegate> transition = options[optionTransition];
      if (transition) {
        controller.transitioningDelegate = transition;
        controller.modalPresentationStyle = UIModalPresentationCustom;
      }
      if (options[optionModalTransitionStyle]) {
        controller.modalTransitionStyle = [options[optionModalTransitionStyle] integerValue];
      }
      if (options[optionModalPresentationStyle]) {
        controller.modalPresentationStyle = [options[optionModalPresentationStyle] integerValue];
      }
    }
  }

  UIViewController *top = self.topViewController;
  if (!forcePresent && top.navigationController) {
    [top.navigationController pushViewController:controller animated:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self config:controller message:message];
        [controller view]; // force viewDidLoad to be called
        [controller handleMessage:message];
    });
    return;
  }

  [top presentViewController:forcePresentWithoutNav ? controller : [[UINavigationController alloc] initWithRootViewController:controller] animated:YES completion:^{
      [self config:controller message:message];
      [controller handleMessage:message];
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
  if (!message.options) {
    return;
  }
  NSDictionary *options = message.options;
  if (options[optionNavBar]) {
    [controller.navigationController setNavigationBarHidden:![options[optionNavBar] boolValue] animated:NO];
  }
  if (options[optionToolBar]) {
    [controller.navigationController setToolbarHidden:![options[optionToolBar] boolValue] animated:NO];
  }
  if (options[optionTabBar]) {
    controller.tabBarController.tabBar.hidden = ![options[optionTabBar] boolValue];
  }
  if (options[optionDeviceOrientation]) {
    [[UIDevice currentDevice] setValue:options[optionDeviceOrientation] forKey:@"orientation"];
  }
  if (options[optionAttemptRotationToDeviceOrientation]) {
    [UIViewController attemptRotationToDeviceOrientation];
  }
  if (options[optionStatusBarOrientation]) {
    [[UIApplication sharedApplication] setStatusBarOrientation:(UIInterfaceOrientation) [options[optionStatusBarOrientation] integerValue]];
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