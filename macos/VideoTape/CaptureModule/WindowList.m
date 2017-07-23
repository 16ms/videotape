#import <Cocoa/Cocoa.h>

NSRect getRectForSpecificApp(NSString* processName, NSRect bounds) {
  CGFloat screenHeight = [NSScreen mainScreen].frame.size.height;
  if ([processName isEqualToString:@"Simulator"]) {
    // we need to remove accidental clock numbers changing
    int TITLEBAR_CORRECTION = 35;
    int BLACK_FRAME_CORRECTION = 0;
    return CGRectMake(
                      bounds.origin.x + BLACK_FRAME_CORRECTION,
                      screenHeight - bounds.origin.y - (bounds.size.height),
                      bounds.size.width - BLACK_FRAME_CORRECTION * 2,
                      bounds.size.height - TITLEBAR_CORRECTION);

  }

  return CGRectMake(bounds.origin.x,
                    screenHeight - bounds.origin.y - (bounds.size.height),
                    bounds.size.width, bounds.size.height);
}
void WindowListApplierFunction(const void *inputDictionary, void *context)
{
  NSDictionary *entry = (__bridge NSDictionary*)inputDictionary;
  NSMutableArray *data = (__bridge NSMutableArray*)context;

  // The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
  // However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
  int sharingState = [entry[(id)kCGWindowSharingState] intValue];
  if(sharingState != kCGWindowSharingNone)
  {
    NSMutableDictionary *outputEntry = [NSMutableDictionary dictionary];

    // Grab the application name, but since it's optional we need to check before we can use it.
    NSString *applicationName = entry[(id)kCGWindowOwnerName];
    if(applicationName != NULL)
    {
      // PID is required so we assume it's present.
      NSString *nameAndPID = [NSString stringWithFormat:@"%@ (%@)", applicationName, entry[(id)kCGWindowOwnerPID]];
      outputEntry[@"appKey"] = nameAndPID;
    }
    else
    {
      // The application name was not provided, so we use a fake application name to designate this.
      // PID is required so we assume it's present.
      NSString *nameAndPID = [NSString stringWithFormat:@"((unknown)) (%@)", entry[(id)kCGWindowOwnerPID]];
      outputEntry[@"appKey"] = nameAndPID;
    }

    outputEntry[@"pid"] = entry[(id)kCGWindowOwnerPID]; /// [NSNumber numberWithInt:entry[(id)kCGWindowOwnerPID]];
    outputEntry[@"appName"] = applicationName;


    // Grab the Window Bounds, it's a dictionary in the array, but we want to display it as a string
    CGRect bounds;
    CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)entry[(id)kCGWindowBounds], &bounds);
    if (bounds.size.width == 1) {
      return;
    }
    if (bounds.origin.x == 0) {
      return;
    }
    NSNumber* level = entry[(id)kCGWindowLayer];
    if (!([level intValue] >= 0 && [level intValue] < 1000)) {
      return;
    }

    outputEntry[@"bounds"] = [NSValue
                              valueWithRect:getRectForSpecificApp(applicationName, bounds)];

    // Grab the Window ID & Window Level. Both are required, so just copy from one to the other
    outputEntry[@"windowId"] = entry[(id)kCGWindowNumber];
    outputEntry[@"windowLevel"] = entry[(id)kCGWindowLayer];
    if ([entry[(id)kCGWindowLayer] intValue] > 0) {
      return;
    }

    outputEntry[@"windowIsOnscreen"] = entry[(id)kCGWindowIsOnscreen];
    if (!(BOOL)entry[(id)kCGWindowIsOnscreen]) {
      return;
    }
    outputEntry[@"windowNumber"] = entry[(id)kCGWindowNumber];


    // Finally, we are passed the windows in order from front to back by the window server
    // Should the user sort the window list we want to retain that order so that screen shots
    // look correct no matter what selection they make, or what order the items are in. We do this
    // by maintaining a window order key that we'll apply later.
    // outputEntry[kWindowOrderKey] = @(data.order);
    // data.order++;

    [data addObject:outputEntry];
  }
}
