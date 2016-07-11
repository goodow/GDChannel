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
    UIViewController *child = [self getVisibleOrChildViewController:top.presentingViewController forceChild:YES];
    return child ?: top.presentingViewController;
  }
  return nil;
}

+ (void)show:(UIViewController *)controller message:(id <GDCMessage>)message {
  if (!controller) {
    return;
  }
  GDCViewOptions *viewOptions = message.options.viewOptions;
  if (viewOptions && !viewOptions.redirect) {
//    [controller view]; // force viewDidLoad to be called
//    [self config:controller options:message.options];
    [controller handleMessage:message];
    return;
  }

  UIViewController *found = [self find:controller in:UIApplication.sharedApplication.keyWindow.rootViewController instanceOrClass:YES];
  if (found) {
    [self config:controller viewOptions:viewOptions];
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
  if (viewOptions) {
    objc_setAssociatedObject(controller, _GDCViewOptionsAssociatedKey, viewOptions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    controller.edgesForExtendedLayout = viewOptions.edgesForExtendedLayout;
    controller.hidesBottomBarWhenPushed = viewOptions.hidesBottomBarWhenPushed;
    if ([viewOptions.display isEqualToString:@"present"]) {
      forcePresent = YES;
    } else if ([viewOptions.display isEqualToString:@"presentWithoutNav"]) {
      forcePresentWithoutNav = forcePresent = YES;
    }

    if (forcePresent) {
      // 动画: 仅在 present 时有效
      if (viewOptions.transition) {
        controller.transitioningDelegate = viewOptions.transition;
        controller.modalPresentationStyle = UIModalPresentationCustom;
      }
      controller.modalTransitionStyle = viewOptions.modalTransitionStyle;
      controller.modalPresentationStyle = controller.modalPresentationStyle;
    }
  }

  UIViewController *top = self.topViewController;
  if (!forcePresent && top.navigationController) {
    [top.navigationController pushViewController:controller animated:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self config:controller viewOptions:viewOptions];
        [controller view]; // force viewDidLoad to be called
        [controller handleMessage:message];
    });
    return;
  }

  [top presentViewController:forcePresentWithoutNav ? controller : [[UINavigationController alloc] initWithRootViewController:controller] animated:YES completion:^{
      [self config:controller viewOptions:viewOptions];
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
  UIViewController *child = [self getVisibleOrChildViewController:parent forceChild:NO];
  return child ? [self findTopViewController:child] : parent;
}

+ (void)config:(UIViewController *)controller viewOptions:(GDCViewOptions *)viewOptions {
  if (!viewOptions) {
    return;
  }
  objc_setAssociatedObject(controller, _GDCViewOptionsAssociatedKey, viewOptions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  [controller.navigationController setNavigationBarHidden:!viewOptions.navBar animated:NO];
  [controller.navigationController setToolbarHidden:!viewOptions.toolBar animated:NO];
  controller.tabBarController.tabBar.hidden = !viewOptions.tabBar;
  [controller setNeedsStatusBarAppearanceUpdate];
  if (controller.navigationController) {
    controller.navigationController.navigationBar.barStyle = viewOptions.navBarStyle;
  }
//  if (options[optionStatusBarOrientation]) {
//    [[UIApplication sharedApplication] setStatusBarOrientation:(UIInterfaceOrientation) [options[optionStatusBarOrientation] integerValue]];
//  }
  if (viewOptions.deviceOrientation) {
    [[UIDevice currentDevice] setValue:@(viewOptions.deviceOrientation) forKey:@"orientation"];
  }
  if (viewOptions.attemptRotationToDeviceOrientation) {
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
      UIViewController *child = [GDCViewControllerHelper getVisibleOrChildViewController:instance forceChild:YES];
      BOOL toRtn;
      if (child) {
        toRtn = [child shouldAutorotate];
      } else {
        GDCViewOptions *viewOptions = instance.viewOptions;
        if (viewOptions) {
          toRtn = viewOptions.autorotate;
        } else {
          [invocation invoke];
          [invocation getReturnValue:&toRtn];
        }
      }
      [invocation setReturnValue:&toRtn];
  }                               error:nil];
  [UIViewController aspect_hookSelector:@selector(supportedInterfaceOrientations) withOptions:AspectPositionInstead usingBlock:^(id <AspectInfo> info) {
      NSInvocation *invocation = info.originalInvocation;
      UIViewController *instance = info.instance;
      UIViewController *child = [GDCViewControllerHelper getVisibleOrChildViewController:instance forceChild:YES];
      UIInterfaceOrientationMask toRtn;
      if (child) {
        toRtn = [child supportedInterfaceOrientations];
      } else {
        GDCViewOptions *viewOptions = instance.viewOptions;
        if (viewOptions) {
          toRtn = viewOptions.supportedInterfaceOrientations;
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
      UIViewController *child = [GDCViewControllerHelper getVisibleOrChildViewController:instance forceChild:YES];
      UIInterfaceOrientation toRtn;
      if (child) {
        toRtn = [child preferredInterfaceOrientationForPresentation];
      } else {
        GDCViewOptions *viewOptions = instance.viewOptions;
        if (viewOptions) {
          toRtn = viewOptions.preferredInterfaceOrientationForPresentation;
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
      BOOL toRtn;
      GDCViewOptions *viewOptions = instance.viewOptions;
      if (viewOptions) {
        toRtn = !viewOptions.statusBar;
      } else {
        [invocation invoke];
        [invocation getReturnValue:&toRtn];
      }
      [invocation setReturnValue:&toRtn];
  }                               error:nil];
  [UIViewController aspect_hookSelector:@selector(preferredStatusBarStyle) withOptions:AspectPositionInstead usingBlock:^(id <AspectInfo> info) {
      NSInvocation *invocation = info.originalInvocation;
      UIViewController *instance = info.instance;
      UIStatusBarStyle toRtn;
      GDCViewOptions *viewOptions = instance.viewOptions;
      if (viewOptions) {
        toRtn = viewOptions.statusBarStyle;
      } else {
        [invocation invoke];
        [invocation getReturnValue:&toRtn];
      }
      [invocation setReturnValue:&toRtn];
  }                               error:nil];
}

+ (UIViewController *)getVisibleOrChildViewController:(UIViewController *)parent forceChild:(BOOL)forceChild {
  if ([parent isKindOfClass:UINavigationController.class]) {
    UINavigationController *navigationController = (UINavigationController *) parent;
    return forceChild ? navigationController.topViewController : navigationController.visibleViewController;
  } else if ([parent isKindOfClass:UITabBarController.class]) {
    return ((UITabBarController *) parent).selectedViewController;
  } else {
    return nil;
  }
}

@end