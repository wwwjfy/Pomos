//
//  PomosNotificationDelegate.m
//  Pomos
//
//  Created by Tony Wang on 3/16/13.
//
//

#import "AppDelegate.h"
#import "PomosNotificationDelegate.h"

@implementation PomosNotificationDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
  [[NSNotificationCenter defaultCenter] postNotificationName:TimeUpConfirmedNotification object:nil];
  [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
  return YES;
}

@end
