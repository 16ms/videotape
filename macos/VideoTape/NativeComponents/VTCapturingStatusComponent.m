#import <Cocoa/Cocoa.h>
#import "React/RCTUtils.h"
#import "VTCapturingStatusComponent.h"
#import "CaptureModule.h"

@implementation VTCapturingStatusComponent {
  CaptureModule *captureModule;
  NSProgressIndicator *progressIndicator;
  NSTextField *label;
  NSButton *captureToggle;
  NSButton *button;
}

- (instancetype)init
{
  if (self = [super init]) {
    
    button = [NSButton buttonWithTitle:@"For height" target:self action:nil];
    [self setFrameSize:NSMakeSize(250, button.intrinsicContentSize.height)];
    
    _targetProcess = [NSButton buttonWithTitle:@"For height" target:self action:nil];
    [_targetProcess setFrameSize:(NSMakeSize(250, button.intrinsicContentSize.height))];
    [_targetProcess setFrameOrigin:NSMakePoint(0, 0)];
    [_targetProcess setBezelStyle:NSBezelStyleTexturedRounded];
    [_targetProcess setAction:@selector(showProcessDialog)];
    [_targetProcess setTarget:self];
    [_targetProcess setAttributedTitle:[self formattedTitle:@"Loading..."]];
    [_targetProcess setBezelStyle:NSBezelStyleTexturedRounded];
    
    progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(250 - button.intrinsicContentSize.height, button.intrinsicContentSize.height / 4, button.intrinsicContentSize.height / 2, button.intrinsicContentSize.height / 2)];
    progressIndicator.style = NSProgressIndicatorSpinningStyle;
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator setDisplayedWhenStopped:NO];
    
    label = [NSTextField labelWithString:@"Ready"];
    [label setFrameOrigin:NSMakePoint(200, 0)];
    [label setFont:[NSFont systemFontOfSize:11]];
    [label setTextColor:[NSColor colorWithSRGBRed:0 green:0 blue:0 alpha:0.5]];
    [label setHidden:YES];
    
    captureToggle = [NSButton buttonWithImage:[NSImage imageNamed:@"Videotape"] target:self action:@selector(toggle)];
////    captureToggle = [[NSButton alloc] initWithFrame:NSMakeRect(200, 0, 40, button.intrinsicContentSize.height)];
//    [captureToggle setFrame:NSMakeRect(200, 0, 40, button.intrinsicContentSize.height)];
//    [captureToggle setButtonType:NSButtonTypeOnOff];
//    [captureToggle setImage:[NSImage imageNamed:@"Videotape"]];
//    [captureToggle setTarget:self];
//    [captureToggle setAction:@selector(toggle)];
    // [captureToggle setEnabled:NO];

    
    [self startLoading];
    [self addSubview:_targetProcess];
    [self addSubview:progressIndicator];
    [self addSubview:label];
  }
  return self;
}

-(CGSize)size
{
  return button.frame.size;
}

- (void)startLoading
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [progressIndicator startAnimation:self];
    [label setHidden:YES];
  });
}

- (void)stopLoading
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [progressIndicator stopAnimation:self];
    [label setHidden:NO];
  });
}

- (void)setCaptureModule:(CaptureModule *)_captureModule
{
  captureModule = _captureModule;
}

-(NSAttributedString *)formattedTitle:(NSString *)title {
  NSFont *font = [NSFont systemFontOfSize:11];
  NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:font
                                                              forKey:NSFontAttributeName];
  return [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
}
                     
- (void)showProcessDialog
{
  NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Windowlist"];
  NSArray *windowList = [captureModule windowList];

  for (int i = 0; i < windowList.count; i++)
  {
    NSDictionary *process = windowList[i];
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(chooseProcess:)];
    [menuItem setTag:i];
    NSRect rect = [process[@"bounds"] rectValue];
    menuItem.title = [NSString stringWithFormat:@"%@ (%ix%i)", process[@"appName"], (int)rect.size.width, (int)rect.size.height];
    [menu addItem:menuItem];
  }

  [menu popUpMenuPositioningItem:[menu itemAtIndex:[menu itemArray].count / 2] atLocation:[NSEvent mouseLocation] inView:nil];
}

- (void)chooseProcess:(NSMenuItem *)sender
{
  NSDictionary *process = captureModule.windowList[sender.tag];
  [self tryToSetTargetProcess:[process[@"pid"] integerValue] appName:process[@"appName"]];
}

- (BOOL)tryToSetTargetProcess:(NSString *)appName
{
  [_targetProcess setAttributedTitle:[self formattedTitle:[NSString stringWithFormat:@"Waiting for %@...", appName]]];
  NSInteger pid = [captureModule findPIDByAppName:appName];
  return [self tryToSetTargetProcess:pid appName:appName];
}

- (BOOL)tryToSetTargetProcess:(NSInteger)pid appName:(NSString *)appName
{
  if ([captureModule setTargetProcessByPID:pid]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [_targetProcess setAttributedTitle:[self formattedTitle:appName]];
      [[RCTSharedApplication() mainWindow] setTouchBar:nil]; // reset
    });
    return YES;
  } else {
    return NO;
  }
}

-(void)toggle
{
  
}

@end
