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
@property (weak) IBOutlet NSTextField *endsAtLabel;

- (IBAction)onClick:(id)sender;


@end
