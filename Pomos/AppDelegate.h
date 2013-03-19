//
//  AppDelegate.h
//  Pomos
//
//  Created by Tony Wang on 3/15/13.
//
//

#import <Cocoa/Cocoa.h>

static NSString *TimeUpConfirmedNotification = @"TimeUpConfirmedNotification";

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;

@end
