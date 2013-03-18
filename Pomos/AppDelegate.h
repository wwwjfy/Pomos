//
//  AppDelegate.h
//  Pomos
//
//  Created by Tony Wang on 3/15/13.
//
//

#import <Cocoa/Cocoa.h>
#import "PomosNotificationDelegate.h"

#define SESSION_LENGTH 25 * 60
#define BREAK_LENGTH 5 * 60

static NSString *TimeUpConfirmedNotification = @"TimeUpConfirmedNotification";

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *countDownLabel;


@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak) IBOutlet NSButton *theButton;

- (IBAction)saveAction:(id)sender;
- (IBAction)onClick:(id)sender;

@end
