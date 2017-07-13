#import <AVFoundation/AVFoundation.h>

@interface FrameWithMetadata: NSObject

@property (nonatomic, copy) NSImage *image;
@property (nonatomic) NSUInteger touch;
@property (nonatomic) NSPoint touchLocation;
@property (nonatomic) BOOL diff;
@property (nonatomic) CMTime presentationTime;
@property (nonatomic) CMTime duration;

@end

@interface FramesStorage : NSObject

- (instancetype)initWithCapacity:(NSUInteger)numItems;// NS_DESIGNATED_INITIALIZER;

- (void)addFrame:(FrameWithMetadata *)frameWithMetadata;
- (void)addFrame:(FrameWithMetadata *)frameWithMetadata index:(NSUInteger)index;
- (FrameWithMetadata *)objectAtIndex:(NSUInteger)index;
- (BOOL)isDroppedFrame:(NSUInteger)index;
- (NSSize)size;

- (NSUInteger)count;

@end
