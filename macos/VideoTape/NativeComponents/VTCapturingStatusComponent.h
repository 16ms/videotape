#import <Cocoa/Cocoa.h>
#import "CaptureModule.h"

@interface VTCapturingStatusComponent : NSView

@property (nonatomic, strong) NSButton *targetProcess;

- (CGSize)size;


- (void)startLoading;
- (void)stopLoading;
- (BOOL)tryToSetTargetProcess:(NSString *)appName;
- (void)setCaptureModule:(CaptureModule *)captureModule;

@end
