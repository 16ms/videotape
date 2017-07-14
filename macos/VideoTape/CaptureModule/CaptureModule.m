#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <React/RCTConvert.h>

#import "CaptureModule.h"
#import "CEMovieMaker.h"
#import "ImageProcessing.h"
#import "FramesStorage.h"
#import "WindowList.h"

//typedef union {
//  uint32_t raw;
//  unsigned char bytes[4];
//  struct {
//    char red;
//    char green;
//    char blue;
//    char alpha;
//  } __attribute__ ((packed)) pixels;
//} FBComparePixel;

@implementation CaptureModule {
  Float64 prevTime;
  NSImage* prevframe;
  NSRunningApplication *capturingApp;
  AVCaptureSession *session;
  long framesIndex;
  long prevFramesIndex;
  FramesStorage *framesStorage;
  dispatch_queue_t framesQueue;
  NSTimer *timer;
  AVCaptureScreenInput *input;
  int similarPreviousFrames;
  int totalPreviousFrames;
}


- (instancetype)init
{
  self = [super init];
  if (self) {
    framesStorage = [[FramesStorage alloc] initWithCapacity:FRAMES_STORAGE_CAPACITY];
    self.settings = [[NSMutableDictionary alloc] init];
    self.settings[@"framesLimitPerSegment"] = @(FRAMES_STORAGE_CAPACITY / 3);
    self.capturing = NO;
  }
   return self;
}

- (void)mergeSettings:(NSDictionary*)newSettings
{
  [_settings addEntriesFromDictionary:newSettings];
}

-(NSMutableArray *)getWindowList
{
  CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
  NSMutableArray * prunedWindowList = [NSMutableArray array];
  CFArrayApplyFunction(windowList,
                       CFRangeMake(0, CFArrayGetCount(windowList)),
                       &WindowListApplierFunction, (__bridge void *)(prunedWindowList));
  CFRelease(windowList);
  return prunedWindowList;
}

- (NSArray *)windowList
{
  return [self getWindowList];
}

- (NSInteger)findPIDByAppName:(NSString*)appName
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"appName==%@", appName];
  NSArray *res = [[self getWindowList] filteredArrayUsingPredicate:predicate];
  if (res.count == 0) {
    return -1;
  }
  return [res[0][@"pid"] intValue];
}

- (BOOL)setTargetProcessByPID:(NSUInteger)pid
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pid==%ld", (long)pid];
  NSArray *res = [[self getWindowList] filteredArrayUsingPredicate:predicate];
  if (res.count == 0) {
    return NO;
  }
  self.pid = pid;
  self.settings[@"appName"] = res[0][@"appName"];
  [self.delegate onSettingsChange:self.settings];
  [self.delegate onCapturingStateChange:CapturingInitialized body:@{@"pid": @(pid)}];
  return YES;
}

-(NSDictionary *)getWindowStateForApp
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pid==%ld", (long)self.pid];
  NSArray *res = [[self getWindowList] filteredArrayUsingPredicate:predicate];
  if (res.count > 0) {
     return res[0];
  }
  return nil;
}

-(void)start
{
  framesIndex = 0;
  prevFramesIndex = 0;
  
  NSDictionary *windowState = [self getWindowStateForApp];
  if (!windowState) {
    [self.delegate
        onCapturingStateChange:CapturingError
                          body:@{
                            @"error" : [NSString
                                stringWithFormat:@"Internal error, couldn't "
                                                 @"find process with pid %lu",
                                                 (unsigned long)self.pid]
                          }];
    return;
  }
  capturingApp = [NSRunningApplication runningApplicationWithProcessIdentifier:(int)self.pid];
  [self ensureAppIsOnTop];
  
  session = [[AVCaptureSession alloc] init];
  
  // Set the session preset as you wish
  session.sessionPreset = AVCaptureSessionPresetHigh;
  
  CGDirectDisplayID displayId = kCGDirectMainDisplay;
  
  input = [[AVCaptureScreenInput alloc] initWithDisplayID:displayId];
  input.minFrameDuration = CMTimeMake(1, FPS_INPUT);
  input.cropRect = ((NSValue *)windowState[@"bounds"]).rectValue;
  input.capturesCursor = NO; // no need to show a cursor here
  input.capturesMouseClicks = YES;
  if ([session canAddInput:input]) {
    [session addInput:input];
  }
  
  AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
  [session addOutput:output];
  output.alwaysDiscardsLateVideoFrames = NO;
  output.videoSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
  
  prevTime = 0.0f;
  
  [session startRunning];
  
  prevframe = [[NSImage alloc] init];
  
  framesQueue = dispatch_queue_create("framesQueue", NULL);
  [output setSampleBufferDelegate:self queue:framesQueue];
  
  timer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                   target:self
                                 selector:@selector(checkCapturingAppStatus)
                                 userInfo:nil
                                  repeats:YES];
  
  [self.delegate onCapturingStateChange:CapturingStarted body:nil];
  self.capturing = YES;
}

-(void)ensureAppIsOnTop
{  
  [capturingApp activateWithOptions:NSApplicationActivateIgnoringOtherApps];
}

-(void)stop
{
  self.capturing = NO;
  [session stopRunning];
  [timer invalidate];
  [self.delegate onCapturingStateChange:CapturingInitialized body:nil];

}

- (void)checkCapturingAppStatus
{
  if (!capturingApp.isActive && session.isRunning) {
    [self.delegate onCapturingStateChange:CapturingPaused body:nil];
    [session stopRunning];
    return;
  }
  NSDictionary *windowState = [self getWindowStateForApp];
  input.cropRect = ((NSValue *)windowState[@"bounds"]).rectValue;
  if (capturingApp.isActive && !session.isRunning) {
    [self ensureAppIsOnTop];
    [self.delegate onCapturingStateChange:CapturingStarted body:nil];
    [session startRunning];
  }
  
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
  // TODO:
  // 1. Support for https://developer.apple.com/reference/coremedia/kcmsamplebufferattachmentkey_droppedframereason?language=objc
  //
  CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
  CMTime duration = CMSampleBufferGetOutputDuration(sampleBuffer);
  
  // if the target process isn't  on the screen,
  // we can't capture the screen
  // because we use AVFoundation APIs
  if (!capturingApp || !capturingApp.isActive) {
    return;
  }
  static mach_timebase_info_data_t    sTimebaseInfo;
  if ( sTimebaseInfo.denom == 0 ) {
    (void) mach_timebase_info(&sTimebaseInfo);
  }
  __block NSUInteger mouseState = [NSEvent pressedMouseButtons];
  __block NSPoint mouseLocation = CGPointMake(
                                              [NSEvent mouseLocation].x - input.cropRect.origin.x,
                                              [NSEvent mouseLocation].y - input.cropRect.origin.y);
  
  if (mouseState > 0) {
    NSLog(@"mouseState!");
  }
  
  __block NSImage *image = [self imageFromSampleBuffer:sampleBuffer];
  dispatch_async(framesQueue, ^{
    if (prevframe != nil && prevframe.size.width > 0) {
      totalPreviousFrames++;
      NSBitmapImageRep* previous = (NSBitmapImageRep *) prevframe.representations[0];
      NSBitmapImageRep* current = (NSBitmapImageRep *) image.representations[0];
      
      BOOL equalToPrevious = [self fb_compareWithImage:previous referenceImage:current tolerance:0];
      
      // In order to detect pauses in frames movements we need to
      // store the total amount of similar frames
      // That's how we can distinguish dropped frames from the pauses
      if (equalToPrevious) {
        similarPreviousFrames++;
      } else {
        similarPreviousFrames = 0;
      }
      
      // One of the following should be true to finish recording
      // and start processing captured data:
      // 1. similarPreviousFrames gets bigger than certain amount of frames
      //    (PAUSE_THRESHOLD which can be 3 frames or more)
      // 2. We're overcoming the limit set by settings (e.g. 100 frames) for
      //    an infinite animation

      //
      if ((framesIndex >= 0 &&
           similarPreviousFrames > PAUSE_THRESHOLD &&
           totalPreviousFrames > similarPreviousFrames + 10 && mouseState == 0) ||
          (totalPreviousFrames > [self.settings[@"framesLimitPerSegment"] integerValue])) {
        [self processCapturedFrames];
        similarPreviousFrames = 0;
        totalPreviousFrames = 0;
        prevFramesIndex = framesIndex;
        return;
      }
      
      if (similarPreviousFrames > PAUSE_THRESHOLD) {
        // too many similar frames in the row
        // we're waiting for beginning of segment
        totalPreviousFrames = 1;
        return;
      }
      
      FrameWithMetadata *frame = [[FrameWithMetadata alloc] init];
      frame.image = image;
      frame.touch = mouseState;
      frame.diff = !equalToPrevious;
      frame.touchLocation = mouseLocation;
      frame.presentationTime = presentationTime;
      frame.duration = duration;
      
      [framesStorage addFrame:frame index:framesIndex];
      
      if (framesIndex < FRAMES_STORAGE_CAPACITY) {
        framesIndex++;
      } else {
        framesIndex = 0;
      }
      
    }
    prevframe = image;
    prevTime = CMTimeGetSeconds(presentationTime);
  });
}

- (NSImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
  // Get a CMSampleBuffer's Core Video image buffer for the media data
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  // Lock the base address of the pixel buffer
  CVPixelBufferLockBaseAddress(imageBuffer, 0);
  
  // Get the number of bytes per row for the pixel buffer
  void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
  
  // Get the number of bytes per row for the pixel buffer
  size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
  // Get the pixel buffer width and height
  size_t width = CVPixelBufferGetWidth(imageBuffer);
  size_t height = CVPixelBufferGetHeight(imageBuffer);
  
  // Create a device-dependent RGB color space
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  
  // Create a bitmap graphics context with the sample buffer data
  CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                               bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
  // Create a Quartz image from the pixel data in the bitmap graphics context
  CGImageRef quartzImage = CGBitmapContextCreateImage(context);
  // Unlock the pixel buffer
  CVPixelBufferUnlockBaseAddress(imageBuffer,0);
  
  // Free up the context and color space
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  
  if (!quartzImage) {
    NSLog(@"can't do cgimage");
    return nil;
  }
  
  // Create an image object from the Quartz image
  NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:quartzImage];
  // Create an NSImage and add the bitmap rep to it...
  NSImage *image = [[NSImage alloc] init];
  [image addRepresentation:bitmapRep];
  
  // Release the Quartz image
  CGImageRelease(quartzImage);
  
  return (image);
}

- (BOOL)fb_compareWithImage:(NSBitmapImageRep *)image referenceImage:(NSBitmapImageRep *)referenceImage tolerance:(CGFloat)tolerance
{
  // NSAssert(CGSizeEqualToSize(self.size, image.size), @"Images must be same size.");
  
  CGSize referenceImageSize = CGSizeMake(CGImageGetWidth(referenceImage.CGImage), CGImageGetHeight(referenceImage.CGImage));
  CGSize imageSize = CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
  
  // The images have the equal size, so we could use the smallest amount of bytes because of byte padding
  size_t minBytesPerRow = MIN(CGImageGetBytesPerRow(referenceImage.CGImage), CGImageGetBytesPerRow(image.CGImage));
  size_t referenceImageSizeBytes = referenceImageSize.height * minBytesPerRow;
  void *referenceImagePixels = calloc(1, referenceImageSizeBytes);
  void *imagePixels = calloc(1, referenceImageSizeBytes);
  
  if (!referenceImagePixels || !imagePixels) {
    free(referenceImagePixels);
    free(imagePixels);
    return NO;
  }
  
  CGContextRef referenceImageContext = CGBitmapContextCreate(referenceImagePixels,
                                                             referenceImageSize.width,
                                                             referenceImageSize.height,
                                                             CGImageGetBitsPerComponent(referenceImage.CGImage),
                                                             minBytesPerRow,
                                                             CGImageGetColorSpace(referenceImage.CGImage),
                                                             (CGBitmapInfo)kCGImageAlphaPremultipliedLast
                                                             );
  CGContextRef imageContext = CGBitmapContextCreate(imagePixels,
                                                    imageSize.width,
                                                    imageSize.height,
                                                    CGImageGetBitsPerComponent(image.CGImage),
                                                    minBytesPerRow,
                                                    CGImageGetColorSpace(image.CGImage),
                                                    (CGBitmapInfo)kCGImageAlphaPremultipliedLast
                                                    );
  
  if (!referenceImageContext || !imageContext) {
    CGContextRelease(referenceImageContext);
    CGContextRelease(imageContext);
    free(referenceImagePixels);
    free(imagePixels);
    return NO;
  }
  
  CGContextDrawImage(referenceImageContext, CGRectMake(0, 0, referenceImageSize.width, referenceImageSize.height), referenceImage.CGImage);
  CGContextDrawImage(imageContext, CGRectMake(0, 0, imageSize.width, imageSize.height), image.CGImage);
  
  CGContextRelease(referenceImageContext);
  CGContextRelease(imageContext);
  
  BOOL imageEqual = YES;
  
  // Do a fast compare if we can
  //if (tolerance == 0) {
  imageEqual = (memcmp(referenceImagePixels, imagePixels, referenceImageSizeBytes) == 0);
  
  free(referenceImagePixels);
  free(imagePixels);
  
  return imageEqual;
}

- (void)processCapturedFrames
{
  if (totalPreviousFrames > FRAMES_STORAGE_CAPACITY) {
    NSLog(@"Please increase FRAMES_STORAGE_CAPACITY to handle this amount of frames for an individual segment %i", totalPreviousFrames);
    return;
  }

  FramesStorage *framesToExport = [[FramesStorage alloc] init];
  NSMutableArray *metadataToExport = [[NSMutableArray alloc] init];

  long ringBufferIndex = framesIndex > totalPreviousFrames ?
  framesIndex - totalPreviousFrames :
  FRAMES_STORAGE_CAPACITY - (totalPreviousFrames - framesIndex);
  
  // throw away last frames, because they are same
  // except the very last one
  totalPreviousFrames = totalPreviousFrames - PAUSE_THRESHOLD + 1;
  while (totalPreviousFrames > 0) {
    FrameWithMetadata *frame = [framesStorage objectAtIndex:ringBufferIndex];
    NSDictionary *frameMetadata = @{
                                    @"touch": @(frame.touch),
                                    @"diff": @(frame.diff),
                                    };
    
    ringBufferIndex++;
    if (ringBufferIndex >= FRAMES_STORAGE_CAPACITY) {
      ringBufferIndex = 0;
    }
    totalPreviousFrames--;
    [framesToExport addFrame:frame];
    [metadataToExport addObject:frameMetadata];
  }
  
  if (framesToExport.count < PAUSE_THRESHOLD) {
    // empty segment
    return;
  }
  
  NSString *uuid = [[NSUUID UUID] UUIDString];
  [self.delegate
      onCapturingStateChange:CapturingSegmentFound
                        body:@{
                          @"windowState": [self getWindowStateForApp],
                          @"uuid" : uuid,
                          @"createdAt" : @([NSDate date].timeIntervalSince1970),
                          @"fps" : @(FPS_INPUT),
                          @"inputFrame" : @{
                            @"width" : @(input.cropRect.size.width),
                            @"height" : @(input.cropRect.size.height)
                          },
                          @"framesMetadata" : metadataToExport
                        }];
  NSString *snapshotURL = [ImageProcessing saveDiffCanvasIntoFile:framesToExport];
  
  [ImageProcessing createMovie:framesToExport withCompletion:^(NSURL *fileURL) {
    [self.delegate onCapturingStateChange:CapturingSegmentProcessed
                                     body:@{
                                            @"uuid": uuid,
                                            @"movieURL" : fileURL.absoluteString
                                            }];
  }];
  
  [self.delegate onCapturingStateChange:CapturingSegmentProcessed
                                   body:@{
                                          @"uuid": uuid,
                                          @"snapshotURL" : snapshotURL
                                          }];
}



@end
