#import <Cocoa/Cocoa.h>
#import "VTToolbar.h"
#import "VTCapturingStatusComponent.h"
#import "React/RCTBridge.h"
#import "React/RCTEventDispatcher.h"
#import "React/RCTUtils.h"
#import <objc/runtime.h>

static NSTouchBarCustomizationIdentifier RNTouchbarIdentifier = @"RNTouchbarIdentifier";

@implementation NSWindow (TouchBar)

- (NSTouchBar *)preparedTouchBar {
  return objc_getAssociatedObject(self, &RNTouchbarIdentifier);
}

- (void)setPreparedTouchBar:(NSTouchBar *)touchBar {
  objc_setAssociatedObject(self, &RNTouchbarIdentifier, touchBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTouchBar *)makeTouchBar
{
  if (!self.preparedTouchBar) {
     return [[NSTouchBar alloc] init];
  }
  return self.preparedTouchBar;
}

@end

@implementation VTToolbar

- (instancetype)init
{
  if (self = [super init]) {
    _capturingStatusComponent = [[VTCapturingStatusComponent alloc] init];
    _captureModule = [[CaptureModule alloc] init];
    [_capturingStatusComponent setCaptureModule:_captureModule];

    _toolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar"];
    [_toolbar setDelegate:self];
    [_toolbar setSizeMode:NSToolbarSizeModeRegular];
    
    _touchbar = [[NSTouchBar alloc] init];
    _touchbar.customizationIdentifier = RNTouchbarIdentifier;
    [_touchbar setDelegate:self];
    [_touchbar setDefaultItemIdentifiers:@[@"addNew", @"delete", @"targetProcess", @"share"]];
    _touchbar.customizationAllowedItemIdentifiers = @[@"addNew", @"delete", @"targetProcess", @"share"];
    
    _captureToggle = [NSButton buttonWithImage:[NSImage imageNamed:@"Videotape"] target:self action:@selector(handleRecordToggle:)];
    [_captureToggle setButtonType:NSButtonTypeOnOff];
    [_captureToggle setEnabled:NO];
    [_captureToggle setFrameSize:NSMakeSize(50, _capturingStatusComponent.size.height)];
  }
  return self;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(__unused NSToolbar *)toolbar
{
  return @[
           //@"addNew",
           //@"delete",
           @"share",
           NSToolbarFlexibleSpaceItemIdentifier,
           @"targetProcess",
           @"toggleRecording",
           NSToolbarFlexibleSpaceItemIdentifier,
           NSToolbarToggleSidebarItemIdentifier,
           NSToolbarSpaceItemIdentifier,
           ];
}

-(void)handleButtonPress:(__unused id)sender
{
  
}

-(void)handleRecordToggle:(__unused id)sender
{
  if (_captureModule.capturing) {
    [_captureModule stop];
  } else {
    [_captureModule start];
  }
}

- (NSArray *)toolbarDefaultItemIdentifiers:(__unused NSToolbar *)toolbar
{
    return @[
             // NSToolbarFlexibleSpaceItemIdentifier,
             // NSToolbarToggleSidebarItemIdentifier,
             //@"addNew",
             //@"delete",

             NSToolbarFlexibleSpaceItemIdentifier,
             
             @"targetProcess",
             @"toggleRecording",
             NSToolbarFlexibleSpaceItemIdentifier,
              @"share",
             ];
}


- (NSToolbarItem *)toolbar:(NSToolbar * __unused)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL __unused)flag {
  
    // https://developer.apple.com/macos/human-interface-guidelines/icons-and-images/system-icons/
  
    if ([itemIdentifier isEqualToString:@"addNew"]) {
      NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
      NSButton *button = [NSButton buttonWithImage:[NSImage imageNamed:	NSImageNameAddTemplate] target:self action:@selector(handleButtonPress:)];
      [button setBezelStyle:NSTexturedRoundedBezelStyle];
      [item setView:button];
      return item;
    }
 
    if ([itemIdentifier isEqualToString:@"share"]) {
      NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
      NSButton *button = [NSButton buttonWithImage:[NSImage imageNamed:	NSImageNameShareTemplate] target:self action:@selector(handleButtonPress:)];
      [button setBezelStyle:NSTexturedRoundedBezelStyle];
      [item setView:button];
      return item;
    }
  
    if ([itemIdentifier isEqualToString:@"delete"]) {
      NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
      NSButton *button = [NSButton buttonWithImage:[NSImage imageNamed:	NSImageNameRemoveTemplate] target:self action:@selector(handleButtonPress:)];
      [button setBezelStyle:NSTexturedRoundedBezelStyle];
      [item setView:button];
      return item;
    }
  
    if ([itemIdentifier isEqualToString:@"toggleRecording"]) {
      NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
      [item setView:_captureToggle];
      return item;
    }
  
    if ([itemIdentifier isEqualToString:@"targetProcess"]) {
      NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
      [item setView:_capturingStatusComponent];
      return item;
    }
    
    return nil;
    
}

- (nullable NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
  if ([identifier isEqualToString:@"addNew"]) {
    NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
    NSButton *button = [NSButton buttonWithImage:[NSImage imageNamed:	NSImageNameAddTemplate] target:self action:@selector(handleButtonPress:)];
    [item setView:button];
    return item;
    
  }
  
  if ([identifier isEqualToString:@"share"]) {
    NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
    NSButton *button = [NSButton buttonWithImage:[NSImage imageNamed:	NSImageNameShareTemplate] target:self action:@selector(handleButtonPress:)];
    [item setView:button];
    return item;
  }
  
  if ([identifier isEqualToString:@"targetProcess"]) {
    NSPopoverTouchBarItem *item = [[NSPopoverTouchBarItem alloc] initWithIdentifier:identifier];
    [item setCollapsedRepresentationLabel:_capturingStatusComponent.targetProcess.title];
    return item;
  }
  
  if ([identifier isEqualToString:@"toggleRecording"]) {
    NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
    NSButton *button = [NSButton buttonWithImage:[NSImage imageNamed:	NSImageNameStatusAvailable] target:self action:@selector(handleButtonPress:)];
    [item setView:button];
    return item;
  }

  return nil;
}

@end
