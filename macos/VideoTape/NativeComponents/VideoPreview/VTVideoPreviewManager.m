#import "VTVideoPreviewManager.h"
#import "VTVideoPreview.h"
#import <React/RCTViewManager.h>
#import <React/RCTBridge.h>

@implementation VTVideoPreviewManager

RCT_EXPORT_MODULE()

- (NSView *)view
{
  return [[VTVideoPreview alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(src, NSString);

@end
