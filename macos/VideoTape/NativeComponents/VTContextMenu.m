#import <Cocoa/Cocoa.h>
#import "VTContextMenu.h"
#import "React/RCTBridge.h"
#import "React/RCTEventDispatcher.h"
#import "React/RCTUtils.h"

@implementation VTContextMenu

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(showMenu:(NSArray *)menuItems)
{
  NSMenu *menu = [[NSMenu alloc] initWithTitle:@"contextMenuUUID"];
  
  for (int i = 0; i < menuItems.count; i++)
  {
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(handleMenuItemClicking:)];
    [menuItem setTag:i];
    menuItem.title = menuItems[i];
    [menu addItem:menuItem];
  }
  
  [menu popUpMenuPositioningItem:[menu itemAtIndex:[menu itemArray].count / 2] atLocation:[NSEvent mouseLocation] inView:nil];
}

- (void)handleMenuItemClicking:(NSMenuItem *)sender
{
  NSLog(@"menuItem clicked %i", sender.tag);
}


@end
