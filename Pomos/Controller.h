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
@property (weak) IBOutlet NSTextField *finishedLabel;

- (IBAction)onClick:(id)sender;


@end
