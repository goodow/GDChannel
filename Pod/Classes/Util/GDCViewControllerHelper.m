//
// Created by Larry Tin on 15/4/30.
//

#import "GDCViewControllerHelper.h"
#import <objc/runtime.h>
#import "Aspects.h"

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
  objc_setAssociatedObject(controller, _GDCMessageAssociatedKey, message, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
  /* config new controller */
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
  UIViewController *child = [self getVisibleChildViewController:parent];
  return child ? [self findTopViewController:child] : parent;
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
  if (options[optionStatusBar] || options[optionStatusBarStyle]) {
    [controller setNeedsStatusBarAppearanceUpdate];
  }
  if (options[optionStatusBarOrientation]) {
    [[UIApplication sharedApplication] setStatusBarOrientation:(UIInterfaceOrientation) [options[optionStatusBarOrientation] integerValue]];
  }
  if (options[optionDeviceOrientation]) {
    [[UIDevice currentDevice] setValue:options[optionDeviceOrientation] forKey:@"orientation"];
  }
  if (options[optionAttemptRotationToDeviceOrientation]) {
    [UIViewController attemptRotationToDeviceOrientation];
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

+ (void)aspect_hookSelector {
  [UIViewController aspect_hookSelector:@selector(shouldAutorotate) withOptions:AspectPositionInstead usingBlock:^(id <AspectInfo> info) {
      NSInvocation *invocation = info.originalInvocation;
      UIViewController *instance = info.instance;
      UIViewController *child = [GDCViewControllerHelper getVisibleChildViewController:instance];
      BOOL toRtn;
      if (child) {
        toRtn = [child shouldAutorotate];
      } else {
        id autorotate = instance.message.options[optionAutorotate];
        if (autorotate) {
          toRtn = [autorotate boolValue];
        } else {
          [invocation invoke];
          [invocation getReturnValue:&toRtn];
        }
      }
      [invocation setReturnValue:&toRtn];
  } error:nil];
  [UIViewController aspect_hookSelector:@selector(supportedInterfaceOrientations) withOptions:AspectPositionInstead usingBlock:^(id <AspectInfo> info) {
      NSInvocation *invocation = info.originalInvocation;
      UIViewController *instance = info.instance;
      UIViewController *child = [GDCViewControllerHelper getVisibleChildViewController:instance];
      UIInterfaceOrientationMask toRtn;
      if (child) {
        toRtn = [child supportedInterfaceOrientations];
      } else {
        static const char *_key = "_GDCOptionSupportedInterfaceOrientationsKey";
        id supportedInterfaceOrientations = instance.message.options[optionSupportedInterfaceOrientations];
        if (supportedInterfaceOrientations) {
          toRtn = [supportedInterfaceOrientations integerValue];
          objc_setAssociatedObject(instance, _key, @(toRtn), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        } else if (objc_getAssociatedObject(instance, _key)) {
          NSNumber *previousValue = objc_getAssociatedObject(instance, _key);
          toRtn = [previousValue integerValue];
        } else {
          [invocation invoke];
          [invocation getReturnValue:&toRtn];
        }
      }
      [invocation setReturnValue:&toRtn];
  }                               error:nil];
  [UIViewController aspect_hookSelector:@selector(preferredInterfaceOrientationForPresentation) withOptions:AspectPositionInstead usingBlock:^(id <AspectInfo> info) {
      NSInvocation *invocation = info.originalInvocation;
      UIViewController *instance = info.instance;
      UIViewController *child = [GDCViewControllerHelper getVisibleChildViewController:instance];
      UIInterfaceOrientation toRtn;
      if (child) {
        toRtn = [child preferredInterfaceOrientationForPresentation];
      } else {
        id preferredInterfaceOrientationForPresentation = instance.message.options[optionPreferredInterfaceOrientationForPresentation];
        if (preferredInterfaceOrientationForPresentation) {
          toRtn = [preferredInterfaceOrientationForPresentation integerValue];
        } else {
          [invocation invoke];
          [invocation getReturnValue:&toRtn];
        }
      }
      [invocation setReturnValue:&toRtn];
  }                               error:nil];

  [UIViewController aspect_hookSelector:@selector(prefersStatusBarHidden) withOptions:AspectPositionInstead usingBlock:^(id <AspectInfo> info) {
      NSInvocation *invocation = info.originalInvocation;
      UIViewController *instance = info.instance;
      static const char *_key = "_GDCOptionPrefersStatusBarHiddenKey";
      BOOL toRtn;
      if (instance.message.options[optionStatusBar]) {
        toRtn = ![instance.message.options[optionStatusBar] boolValue];
        objc_setAssociatedObject(instance, _key, @(toRtn), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      } else if (objc_getAssociatedObject(instance, _key)) {
        NSNumber *previousValue = objc_getAssociatedObject(instance, _key);
        toRtn = [previousValue boolValue];
      } else {
        [invocation invoke];
        [invocation getReturnValue:&toRtn];
      }
      [invocation setReturnValue:&toRtn];
  }                               error:nil];
  [UIViewController aspect_hookSelector:@selector(preferredStatusBarStyle) withOptions:AspectPositionInstead usingBlock:^(id <AspectInfo> info) {
      NSInvocation *invocation = info.originalInvocation;
      UIViewController *instance = info.instance;
      static const char *_key = "_GDCOptionPreferredStatusBarStyleKey";
      UIStatusBarStyle toRtn;
      if (instance.message.options[optionStatusBarStyle]) {
        toRtn = [instance.message.options[optionStatusBarStyle] integerValue];
        objc_setAssociatedObject(instance, _key, @(toRtn), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      } else if (objc_getAssociatedObject(instance, _key)) {
        NSNumber *previousValue = objc_getAssociatedObject(instance, _key);
        toRtn = [previousValue integerValue];
      } else {
        [invocation invoke];
        [invocation getReturnValue:&toRtn];
      }
      [invocation setReturnValue:&toRtn];
  }                               error:nil];
}

+ (UIViewController *)getVisibleChildViewController:(UIViewController *)parent {
  if ([parent isKindOfClass:UINavigationController.class]) {
    return ((UINavigationController *) parent).visibleViewController;
  } else if ([parent isKindOfClass:UITabBarController.class]) {
    return ((UITabBarController *) parent).selectedViewController;
  } else {
    return nil;
  }
}

@end