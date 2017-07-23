#import <AVFoundation/AVFoundation.h>

@interface FrameWithMetadata: NSObject

@property (nonatomic, copy) NSImage *image;
@property (nonatomic) NSUInteger touch;
@property (nonatomic) NSPoint touchLocation;
@property (nonatomic) BOOL diff;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic) CMTime presentationTime;

@end

@interface FramesStorage : NSObject

- (instancetype)initWithCapacity:(NSUInteger)numItems;// NS_DESIGNATED_INITIALIZER;

- (void)addFrame:(FrameWithMetadata *)frameWithMetadata;
- (void)updateFrame:(FrameWithMetadata *)frameWithMetadata index:(NSUInteger)index;
- (FrameWithMetadata *)objectAtIndex:(NSUInteger)index;
- (NSSize)size;

- (NSUInteger)count;

@end
