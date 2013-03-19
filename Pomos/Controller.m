//
//  Controller.m
//  Pomos
//
//  Created by Tony Wang on 3/19/13.
//
//

#import "Controller.h"
#import "PomosNotificationDelegate.h"

#define SESSION_LENGTH 25 * 60
#define BREAK_LENGTH 5 * 60

enum Mode {
  Initial,
  Working,
  Finished,
  Breaking
};

@interface Controller () {
  enum Mode _mode;
  int _seconds;
  NSTimer *_timer;
  BOOL inBreak;
}

@end

@implementation Controller

@synthesize theButton;

- (id)init {
  if ((self = [super init])) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(timeUpConfirmed:)
                                                 name:TimeUpConfirmedNotification
                                               object:nil];
    _mode = Initial;
  }
  return self;
}

- (void)setSeconds:(int)newValue {
  _seconds = newValue;
  [[self countDownLabel] setStringValue:[NSString stringWithFormat:@"%02d : %02d", _seconds / 60, _seconds % 60]];
  [self setBadge];
}

- (void)setBadge {
  // The basic display rule is:
  // min >= 5, show x min
  // min in [1, 5], show x:y, where x is min, y is 0 or 30 sec
  // if sec > 10, show x-ty, otherwise, show sec
  int min = _seconds / 60;
  int sec = _seconds % 60;
  NSString *badge;
  if (min >= 5) {
    badge = [NSString stringWithFormat:@"%d min", min];
  } else if (min >= 1) {
    badge = [NSString stringWithFormat:@"%d:%02d", min, sec / 30 * 30];
  } else {
    if (sec > 10) {
      badge = [NSString stringWithFormat:@"%d s", sec / 10 * 10];
    } else {
      badge = [NSString stringWithFormat:@"%d s", sec];
    }
  }
  [[[NSApplication sharedApplication] dockTile] setBadgeLabel:badge];
}

- (void)timeUpConfirmed:(NSNotification *)notification {
  if ([_timer isValid]) {
    return;
  }
  if (_mode == Finished || _mode == Initial) {
    [self nextMode];
  }
}

- (void)countingDown:(NSTimer *)timer {
  [self setSeconds:(_seconds - 1)];

  if (_seconds <= 0) {
    NSUserNotification *timeUp = [[NSUserNotification alloc] init];
    if (_mode == Breaking) {
      [timeUp setTitle:@"No more break!"];
      [timeUp setActionButtonTitle:@"Back to work"];
    } else {
      [timeUp setTitle:@"Time Up!"];
      [timeUp setActionButtonTitle:@"I've done .."];
    }
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:timeUp];
    [self nextMode];
  }
}

- (IBAction)onClick:(id)sender {
  if (_mode == Working) {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure to give up this pomodoro?" defaultButton:@"Yes" alternateButton:@"It's a slip" otherButton:nil informativeTextWithFormat:@""];
    [[alert buttons][1] setKeyEquivalent:@"\e"];
    switch ([alert runModal]) {
      case NSAlertAlternateReturn:
        return;
        break;
      default:
        break;
    }
    _mode = Breaking;
  }
  [self nextMode];
}

- (void)nextMode {
  switch (_mode) {
    case Initial:
      [self setSeconds:SESSION_LENGTH];
      _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countingDown:) userInfo:nil repeats:YES];
      [theButton setTitle:@"Give up"];
      _mode = Working;
      break;
    case Working:
      [self setSeconds:BREAK_LENGTH];
      [_timer invalidate];
      [theButton setTitle:@"Break"];
      _mode = Finished;
      break;
    case Finished:
      [self setSeconds:BREAK_LENGTH];
      _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countingDown:) userInfo:nil repeats:YES];
      [theButton setTitle:@"Skip"];
      _mode = Breaking;
      break;
    case Breaking:
      [_timer invalidate];
      [self setSeconds:SESSION_LENGTH];
      [theButton setTitle:@"Start"];
      _mode = Initial;
      break;
    default:
      break;
  }
}

@end
