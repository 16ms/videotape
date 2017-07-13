#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "FramesStorage.h"

@implementation FrameWithMetadata
@end

@implementation FramesStorage
{
    NSMutableArray<FrameWithMetadata *> *framesWithMetadata;
}

- (id)init
{
    if (self = [super init]) {
        framesWithMetadata = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems
{
    if (self = [super init]) {
        framesWithMetadata = [[NSMutableArray alloc] initWithCapacity:numItems];
    }
    return self;
}

- (void)addFrame:(FrameWithMetadata *)frameWithMetadata
{
  if ([frameWithMetadata isNotEqualTo:nil]) {
      [framesWithMetadata addObject:frameWithMetadata];
  } else {
    NSLog(@"Warning: frameWithMetadata is empty");
  }
}

- (void)addFrame:(FrameWithMetadata *)frameWithMetadata index:(NSUInteger)index
{
    if (framesWithMetadata.count > index && ![[framesWithMetadata objectAtIndex:index] isEqual:nil]) {
        [framesWithMetadata replaceObjectAtIndex: index withObject:frameWithMetadata];
    } else {
        [framesWithMetadata addObject:frameWithMetadata];
    }
}

- (FrameWithMetadata *)objectAtIndex:(NSUInteger)index
{
  if (index < framesWithMetadata.count) {
    return [framesWithMetadata objectAtIndex:index];
  }
  return nil;
}

- (NSSize)size
{
    return framesWithMetadata[0].image.size;
}

- (NSUInteger)count
{
    return framesWithMetadata.count;
}
@end
