#import <Cocoa/Cocoa.h>
#import "React/RCTBridgeModule.h"
#import "React/RCTEventEmitter.h"
#import "CaptureModule.h"



@interface VTCaptureModuleProxy : RCTEventEmitter <RCTBridgeModule, VTCapturingProcessDelegate>
@end
