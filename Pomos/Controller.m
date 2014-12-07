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
  NSTimer *_timer;
  BOOL inBreak;
  NSDate *endAt;
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

- (void)setSeconds:(int)seconds {
  [[self countDownLabel] setStringValue:[NSString stringWithFormat:@"%02d : %02d", seconds / 60, seconds % 60]];
  [self setBadge:seconds];
}

- (int)countSeconds {
  int seconds = [endAt timeIntervalSinceNow];
  [self setSeconds:seconds];
  return seconds;
}

- (void)setBadge:(int)seconds {
  if (_mode == Finished || _mode == Initial) {
    return;
  }
  // The basic display rule is:
  // min >= 5, show x min
  // min in [1, 5], show x:y, where x is min, y is 0 or 30 sec
  // if sec > 10, show x-ty, otherwise, show sec
  int min = seconds / 60;
  int sec = seconds % 60;
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

- (void)resetBadge {
  [[[NSApplication sharedApplication] dockTile] setBadgeLabel:nil];
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
  int seconds = [self countSeconds];

  if (seconds <= 0) {
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
      _mode = Working;
      endAt = [NSDate dateWithTimeIntervalSinceNow:SESSION_LENGTH];
      [self countSeconds];
      _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countingDown:) userInfo:nil repeats:YES];
      [theButton setTitle:@"Give up"];
      break;
    case Working:
      _mode = Finished;
      [_timer invalidate];
      [self setSeconds:BREAK_LENGTH];
      [theButton setTitle:@"Break"];
      [self resetBadge];
      break;
    case Finished:
      _mode = Breaking;
      endAt = [NSDate dateWithTimeIntervalSinceNow:BREAK_LENGTH];
      [self countSeconds];
      _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countingDown:) userInfo:nil repeats:YES];
      [theButton setTitle:@"Skip"];
      break;
    case Breaking:
      _mode = Initial;
      [_timer invalidate];
      [self setSeconds:SESSION_LENGTH];
      [theButton setTitle:@"Start"];
      [self resetBadge];
      break;
    default:
      break;
  }
}

@end
