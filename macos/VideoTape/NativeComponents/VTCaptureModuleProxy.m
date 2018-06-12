#import <Cocoa/Cocoa.h>
#import "VTCaptureModuleProxy.h"
#import "VTToolbar.h"
#import "VTCapturingStatusComponent.h"
#import "AppDelegate.h"
#import "React/RCTBridge.h"
#import "React/RCTEventDispatcher.h"
#import "React/RCTUtils.h"
#import <objc/runtime.h>

static NSDictionary *states;

@implementation VTCaptureModuleProxy {
  VTToolbar *toolbar;
}

RCT_EXPORT_MODULE();

- (instancetype)init
{
  if (self = [super init]) {
    toolbar = ((AppDelegate *)[RCTSharedApplication() delegate]).toolbarWrapper;
    [toolbar.captureModule setDelegate:self];

    states = @{
      @(CapturingInitialized) : @"initialized",
      @(CapturingStarted) : @"started",
      @(CapturingError) : @"error",
      @(CapturingSegmentFound) : @"segmentFound",
      @(CapturingSegmentProcessed) : @"segmentProcessed",
      @(CapturingPaused) : @"paused"
    };
  }
  return self;
}

RCT_EXPORT_METHOD(startCapturing)
{
  [toolbar.captureToggle setState:NSOnState];
  [toolbar.captureModule start];
}

RCT_EXPORT_METHOD(stopCapturing)
{
  [toolbar.captureToggle setState:NSOffState];
  [toolbar.captureModule stop];
}


RCT_EXPORT_METHOD(writeToStdout:(NSString *)log)
{
  [log writeToFile:@"/dev/stdout" atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

RCT_EXPORT_METHOD(setSettings:(NSDictionary *)settings)
{
  [toolbar.captureModule mergeSettings:settings];
  if (![toolbar.capturingStatusComponent tryToSetTargetProcess:settings[@"appName"]]) {
    [self stopCapturing];
    [self
        onCapturingStateChange:CapturingError
                          body:@{
                            @"error" : [NSString
                                stringWithFormat:
                                    @"Couldn't find process with given name: %@",
                                    settings[@"appName"]]
                          }];
  } else {
    if ([settings[@"autorun"] boolValue]) {
      [self startCapturing];
    }
  }
}

RCT_EXPORT_METHOD(recordTouchEvent:(NSArray *)event)
{
  [toolbar.captureModule recordTouchEvent:event];
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"onSettingsChange", @"onCapturingStateChange"];
}

- (void)onSettingsChange:(NSDictionary *)settings
{
  [self sendEventWithName:@"onSettingsChange" body:settings];
  if (toolbar.captureModule.pid > 0) {
    [toolbar.captureToggle setEnabled:YES];
  }
}

- (void)onCapturingStateChange:(CapturingState)capturingState body:(NSDictionary *)body
{
  if (capturingState == CapturingInitialized) {
    [toolbar.capturingStatusComponent stopLoading];
  }
  [self sendEventWithName:@"onCapturingStateChange"
                     body:@{
                       @"capturingState" : states[@(capturingState)],
                       @"body" : body ? body : @{}
                     }];
}

@end
