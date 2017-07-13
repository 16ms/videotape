#import <Cocoa/Cocoa.h>
#import <React/RCTEventDispatcher.h>

@interface VTSplitView: NSSplitView

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher * _Nonnull)eventDispatcher NS_DESIGNATED_INITIALIZER;

@end
