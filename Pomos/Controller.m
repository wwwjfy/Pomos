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
  NSURL *plistURL;
  NSDate *date;
  NSDateFormatter *dateFormatter;
}

@property NSUInteger finished;

@end

@implementation Controller

@synthesize theButton;
@synthesize finishedLabel;
@synthesize finished = _finished;

- (id)init {
  if ((self = [super init])) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(timeUpConfirmed:)
                                                 name:TimeUpConfirmedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didShow:)
                                                 name:NSWindowDidBecomeMainNotification
                                               object:nil];
    _mode = Initial;

    NSURL *pDir = [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                          inDomain:NSUserDomainMask
                                                 appropriateForURL:nil
                                                            create:NO
                                                             error:nil] URLByAppendingPathComponent:@"Pomos"];
    [[NSFileManager defaultManager] createDirectoryAtURL:pDir
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:nil];
    plistURL = [pDir URLByAppendingPathComponent:@"pomos.plist"];

    NSDictionary *dict = [self readInfo];

    if (dict[@"Date"]) {
      date = dict[@"Date"];
    } else {
      date = [NSDate date];
    }
    if (dict[@"Finished"]) {
      [self setFinished:((NSNumber*)dict[@"Finished"]).unsignedIntegerValue];
    } else {
      [self setFinished:0];
    }
    [self checkFinished];

    dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%H:%M" allowNaturalLanguage:NO];
  }
  return self;
}

- (void)didShow:(NSNotification *)notification {
  [self setFinished:_finished];
}

- (NSUInteger)finished {
  return _finished;
}

- (void)setFinished:(NSUInteger)finished {
  _finished = finished;
  [[self finishedLabel] setStringValue:[NSString stringWithFormat:@"%lu", (unsigned long)finished]];
  [self saveInfo];
}

- (NSDictionary *)readInfo {
  return [[NSString stringWithContentsOfURL:plistURL
                                   encoding:NSUTF8StringEncoding
                                      error:nil] propertyListFromStringsFileFormat];
}

- (void)saveInfo {
  NSData *data = [NSPropertyListSerialization dataWithPropertyList:@{@"Date": self->date,
                                                                     @"Finished": [NSNumber numberWithUnsignedInteger:self.finished]}
                                                            format:NSPropertyListXMLFormat_v1_0
                                                           options:0
                                                             error:nil];
  if (data) {
    [data writeToURL:plistURL options:NSDataWritingAtomic error:nil];
  }
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
    [self nextMode];
  }
}

- (void)sendNotificationWithTitle:(NSString *)title withButton:(NSString *)buttonTitle {
  NSUserNotification *timeUp = [[NSUserNotification alloc] init];
  [timeUp setTitle:title];
  [timeUp setActionButtonTitle:buttonTitle];
  [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:timeUp];
}

- (IBAction)onClick:(id)sender {
  if (_mode == Working) {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure to give up this pomodoro?" defaultButton:@"Yes" alternateButton:@"It's a slip" otherButton:nil informativeTextWithFormat:@""];
    [[alert buttons][1] setKeyEquivalent:@"\e"];
    if ([alert runModal] == NSAlertAlternateReturn) {
      return;
    }
    _mode = Breaking;
  } else if (_mode == Breaking) {
    [_timer invalidate];
    _mode = Initial;
  }
  [self nextMode];
}

- (void)checkFinished {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSInteger components = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);

  NSDateComponents *firstComponents = [calendar components:components fromDate:self->date];
  NSDateComponents *secondComponents = [calendar components:components fromDate:[NSDate date]];

  NSDate *date1 = [calendar dateFromComponents:firstComponents];
  NSDate *date2 = [calendar dateFromComponents:secondComponents];

  if ([date1 compare:date2] != NSOrderedSame) {
    self->date = [NSDate date];
    [self setFinished:0];
  }
}

- (void)nextMode {
  [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
  [self checkFinished];
  switch (_mode) {
    case Initial:
      _mode = Working;
      endAt = [NSDate dateWithTimeIntervalSinceNow:SESSION_LENGTH];
      [self countSeconds];
      _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countingDown:) userInfo:nil repeats:YES];
      [theButton setTitle:@"Give up"];
      [[self endsAtLabel] setStringValue:[NSString stringWithFormat:@"Ends at %@", [self->dateFormatter stringFromDate:endAt]]];
      [[self endsAtLabel] setHidden:NO];
      break;
    case Working:
      _mode = Finished;
      [_timer invalidate];
      [self setSeconds:BREAK_LENGTH];
      [theButton setTitle:@"Break"];
      [self resetBadge];
      [self setFinished:self.finished+1];
      [self sendNotificationWithTitle:@"Time Up!" withButton:@"Take a break"];
      break;
    case Finished:
      _mode = Breaking;
      endAt = [NSDate dateWithTimeIntervalSinceNow:BREAK_LENGTH];
      [self countSeconds];
      _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countingDown:) userInfo:nil repeats:YES];
      [theButton setTitle:@"Skip"];
      [[self endsAtLabel] setStringValue:[NSString stringWithFormat:@"Ends at %@", [self->dateFormatter stringFromDate:endAt]]];
      [[self endsAtLabel] setHidden:NO];
      break;
    case Breaking:
      _mode = Initial;
      [_timer invalidate];
      [self setSeconds:SESSION_LENGTH];
      [theButton setTitle:@"Start"];
      [self resetBadge];
      [self sendNotificationWithTitle:@"Back to work" withButton:@"Sure"];
      break;
    default:
      break;
  }
}

@end
