//
//  Controller.h
//  Pomos
//
//  Created by Tony Wang on 3/19/13.
//
//

#import <Foundation/Foundation.h>

@interface Controller : NSObject
@property (weak) IBOutlet NSButton *theButton;
@property (weak) IBOutlet NSTextField *countDownLabel;
- (IBAction)onClick:(id)sender;

@end
