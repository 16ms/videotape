#import "VideoTapeModule.h"
#import "VideoTapeManager.h"

@implementation RCTVideoTape

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(start)
{
  [VideoTapeManager startCapturing];
}

RCT_REMAP_METHOD(getLastSegment,
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  resolve([VideoTapeManager getLastSegment]);
}

RCT_EXPORT_METHOD(stop)
{
  [VideoTapeManager stopCapturing];
}

@end;
