#import "VTSplitViewManager.h"
#import "VTSplitView.h"
#import <React/RCTViewManager.h>
#import <React/RCTBridge.h>

@implementation VTSplitViewManager

RCT_EXPORT_MODULE()

- (NSView *)view
{
  return [[VTSplitView alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
}

@end
