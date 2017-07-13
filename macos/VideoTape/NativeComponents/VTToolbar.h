#import <Cocoa/Cocoa.h>
#import "React/RCTBridgeModule.h"
#import "React/RCTEventEmitter.h"
#import "CaptureModule.h"
#import "VTCapturingStatusComponent.h"

@interface NSWindow (TouchBar)
  @property (nonatomic, copy) NSTouchBar *preparedTouchBar;
@end

@interface VTToolbar : NSObject <NSToolbarDelegate, NSTouchBarDelegate>

@property (nonatomic, strong) NSToolbar *toolbar;
@property (nonatomic, strong) NSTouchBar *touchbar;
@property (nonatomic, strong) CaptureModule *captureModule;
@property (nonatomic, strong) VTCapturingStatusComponent *capturingStatusComponent;
@property (nonatomic, strong) NSButton *captureToggle;

@end
