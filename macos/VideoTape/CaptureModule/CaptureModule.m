#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <React/RCTConvert.h>

#import "CaptureModule.h"
#import "CEMovieMaker.h"
#import "ImageProcessing.h"
#import "FramesStorage.h"
#import "WindowList.h"

@implementation CaptureModule {
  NSImage* prevFrame;
  NSRunningApplication *capturedApp;
  AVCaptureSession *session;
  long framesIndex;
  long prevFramesIndex;
  int similarPreviousFrames;
  int totalPreviousFrames;
  FramesStorage *framesStorage;
  dispatch_queue_t framesMainQueue;
  dispatch_queue_t framesAdditionalQueue;
  NSTimer *timer;
  AVCaptureScreenInput *input;
  NSTimeInterval prevTimestamp;
  NSTimeInterval offsetTime;
  CMTime offsetTimeAsCMTime;
  NSMutableArray* unproccessedTouches;
}


- (instancetype)init
{
  self = [super init];
  if (self) {
    framesStorage = [[FramesStorage alloc] initWithCapacity:FRAMES_STORAGE_CAPACITY];
    unproccessedTouches = [[NSMutableArray alloc] init];
    self.settings = [[NSMutableDictionary alloc] init];
    self.settings[@"framesLimitPerSegment"] = @(2 * FRAMES_STORAGE_CAPACITY / 3);
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
  capturedApp = [NSRunningApplication runningApplicationWithProcessIdentifier:(int)self.pid];
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
  
  dispatch_queue_attr_t highPriorityAttr = dispatch_queue_attr_make_with_qos_class (DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED,-1);
  framesMainQueue = dispatch_queue_create("VideoTape.framesMainQueue", highPriorityAttr);
  framesAdditionalQueue = dispatch_queue_create("VideoTape.framesAdditionalQueue", NULL);
  [output setSampleBufferDelegate:self queue:framesMainQueue];
  
  timer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                   target:self
                                 selector:@selector(checkCapturedAppStatus)
                                 userInfo:nil
                                  repeats:YES];
  
  [session startRunning];
  [self.delegate onCapturingStateChange:CapturingStarted body:nil];
  self.capturing = YES;
  offsetTime = [NSDate timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970;
  prevTimestamp = offsetTime;
  prevFrame = [[NSImage alloc] init];
}

-(void)ensureAppIsOnTop
{  
  [capturedApp activateWithOptions:NSApplicationActivateIgnoringOtherApps];
}

-(void)stop
{
  if (self.capturing) {
    self.capturing = NO;
    [session stopRunning];
    [timer invalidate];
    [self.delegate onCapturingStateChange:CapturingInitialized body:nil];
  }
}

- (void)checkCapturedAppStatus
{
  if (!capturedApp.isActive && session.isRunning) {
    [self.delegate onCapturingStateChange:CapturingPaused body:nil];
    [session stopRunning];
    return;
  }
  NSDictionary *windowState = [self getWindowStateForApp];
  input.cropRect = ((NSValue *)windowState[@"bounds"]).rectValue;
  if (capturedApp.isActive && !session.isRunning) {
    [self ensureAppIsOnTop];
    [self.delegate onCapturingStateChange:CapturingStarted body:nil];
    [session startRunning];
  }
  
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, 6_0)
{
  // TODO:
  // 1. Support for https://developer.apple.com/reference/coremedia/kcmsamplebufferattachmentkey_droppedframereason?language=objc
  //
  NSLog(@"Dropped!");
}

- (void)addFrameToBuffer:(NSImage *)image touch:(NSUInteger)touch diff:(bool)diff timestamp:(NSTimeInterval)timestamp touchLocation:(CGPoint)touchLocation durationTime:(CMTime)durationTime
{
  FrameWithMetadata *frame = [[FrameWithMetadata alloc] init];
  frame.image = image;
  frame.touch = touch;
  frame.diff = diff;
  frame.touchLocation = touchLocation;
  frame.timestamp = timestamp;
  frame.presentationTime = durationTime;
  
  [framesStorage updateFrame:frame index:framesIndex];
  
  // pretend that this is a ring buffer
  // TODO: hide this detail into framesStorage
  if (framesIndex < FRAMES_STORAGE_CAPACITY) {
    framesIndex++;
  } else {
    framesIndex = 0;
  }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
  // if the target process isn't  on the screen,
  // we can't capture the screen
  // because we use AVFoundation APIs
  if (!capturedApp || !capturedApp.isActive) {
    [self processCapturedFrames];
    similarPreviousFrames = 0;
    totalPreviousFrames = 0;
    prevFramesIndex = framesIndex;
    return;
  }
  if (CMTIME_IS_INVALID(offsetTimeAsCMTime)) {
    offsetTimeAsCMTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
  }
  
  static mach_timebase_info_data_t    sTimebaseInfo;
  if ( sTimebaseInfo.denom == 0 ) {
    (void) mach_timebase_info(&sTimebaseInfo);
  }
  // uint64_t started = mach_absolute_time();
  // double time = (mach_absolute_time()) * sTimebaseInfo.numer / sTimebaseInfo.denom / 1000 / 1000 / 1000;
 
  CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
  __block NSTimeInterval timestamp = CMTimeGetSeconds(CMTimeSubtract(presentationTime, offsetTimeAsCMTime)) + offsetTime;

  prevTimestamp = timestamp;
  
  
  
  //NSLog(@"presentationTime %f", CMTimeGetSeconds(CMTimeSubtract(presentationTime, offsetTimeAsCMTime)) + offsetTime);
  CMTime durationTime = CMSampleBufferGetDuration(sampleBuffer);
//  __block NSUInteger mouseState = [NSEvent pressedMouseButtons];
//  __block NSPoint mouseLocation = CGPointMake(
//                                              [NSEvent mouseLocation].x - input.cropRect.origin.x,
//                                              [NSEvent mouseLocation].y - input.cropRect.origin.y);
  __block NSUInteger mouseState = 0;
  __block NSPoint mouseLocation = CGPointMake(0, 0);
  for (int i=0; i< [unproccessedTouches count]; i++) {
    NSTimeInterval diff = [unproccessedTouches[i][@"timestamp"] doubleValue] - timestamp;
    if (totalPreviousFrames == 0 && fabs(diff) < 2.0 / FPS_INPUT) {
      NSLog(@"-> timestamp %f diff: %f totalPreviousFrames", timestamp, diff);
      totalPreviousFrames = 1;
      mouseLocation = CGPointMake(
                                  [unproccessedTouches[i][@"x"] intValue],
                                  [unproccessedTouches[i][@"y"] intValue]);
      mouseState = 1;
      [self
          addFrameToBuffer:prevFrame
                     touch:1
                      diff:YES
                 timestamp:timestamp
             touchLocation:mouseLocation
              durationTime:CMTimeMake(1, FPS_INPUT)];
    }
    if (totalPreviousFrames < 2 && fabs(diff) < 1 / FPS_INPUT) {
      NSLog(@"timestamp Found one!");
      mouseState = 1;
      mouseLocation = CGPointMake(
                                  [unproccessedTouches[i][@"x"] intValue],
                                  [unproccessedTouches[i][@"y"] intValue]);
      
    }
    [unproccessedTouches removeObjectAtIndex:i];
  }

  
  // uint64_t started = mach_absolute_time();
  __block NSImage *image = [ImageProcessing imageFromSampleBuffer:sampleBuffer];
  // double ms = (mach_absolute_time() - started) * sTimebaseInfo.numer / sTimebaseInfo.denom / 1000.0 / 1000.0;
  // NSLog(@"image constructed in %f %lld", ms, mach_absolute_time() - started);
  dispatch_async(framesAdditionalQueue, ^{
    if (prevFrame != nil && prevFrame.size.width > 0) {
      totalPreviousFrames++;
      NSBitmapImageRep* previous = (NSBitmapImageRep *) prevFrame.representations[0];
      NSBitmapImageRep* current = (NSBitmapImageRep *) image.representations[0];
      
      BOOL equalToPrevious = [ImageProcessing compareBitmaps:previous referenceImage:current];
      
      // In order to detect pauses in frames movements we need to
      // store the total amount of similar frames
      // That's how we can naively distinguish dropped frames from the pauses
      if (equalToPrevious && mouseState == 0) {
        similarPreviousFrames++;
      } else {
        similarPreviousFrames = 0;
      }
      
      // --- DETECT ENDING OF SEGMENT ---
      // One of the following should be true to finish recording
      // and start processing captured data:
      // 1. similarPreviousFrames getting bigger than certain amount of frames
      //    (PAUSE_THRESHOLD which can be 3 frames or more)
      // 2. totalPreviousFrames overcoming the limit set by settings (e.g. 100 frames) for
      //    an infinite animation
      if ((similarPreviousFrames > PAUSE_THRESHOLD &&
           totalPreviousFrames > similarPreviousFrames + CAPTURE_THRESHOLD && mouseState == 0) ||
          (totalPreviousFrames > [self.settings[@"framesLimitPerSegment"] integerValue])) {
        NSLog(@"timestamp finish");
        [self processCapturedFrames];
        similarPreviousFrames = 0;
        totalPreviousFrames = 0;
        prevFramesIndex = framesIndex;
        return;
      }
      
      // --- DETECT PAUSES ---
      // too many similar frames in the row
      // we're waiting for beginning of segment
      if (similarPreviousFrames > PAUSE_THRESHOLD) {
        if (totalPreviousFrames > 1) {
          NSLog(@"timestamp pause");
        }
        totalPreviousFrames = 0;
        return;
      }
      
      NSLog(@"timestamp %f %lu %hhd %li totalPreviousFrames %i",
            timestamp,
            (unsigned long)mouseState,
            equalToPrevious,
            framesIndex,
            totalPreviousFrames);
      
      
      
      [self addFrameToBuffer:prevFrame
                       touch:mouseState
                        diff:!equalToPrevious
                   timestamp:timestamp
               touchLocation:mouseLocation
                durationTime:durationTime];
      
    } else {
      NSLog(@"DEBUG: no prevImage!");
    }
    prevFrame = image;
  });
}

- (void)recordTouchEvent:(NSArray * _Nonnull)event
{
  if (!self.capturing) {
    return;
  }
  for (int i =0; i < event.count; i++) {
    NSDictionary *touchData = event[i];
    bool found = NO;
    // search buffer for right timestamp
    for (int j = 0; j < framesStorage.count; j++) {
   
      FrameWithMetadata *frame = [framesStorage objectAtIndex:j];
      
      NSTimeInterval diff = [touchData[@"timestamp"] doubleValue] - frame.timestamp;
        NSLog(@"RECORD TOUCH: %f %f %f", [touchData[@"timestamp"] doubleValue], frame.timestamp, diff);
      if (fabs(diff) < 1 / FPS_INPUT) {
        // set touch state and put it back to buffer storage
        frame.touch = 1;
        frame.touchLocation = NSMakePoint([touchData[@"x"] floatValue], [touchData[@"y"] floatValue]);
        [framesStorage updateFrame:frame index:j];
        found = YES;
        break;
      }
    }
    
    if (!found) {
      // if we don't find any ready frames we should set the global touch state
      [unproccessedTouches addObject:touchData];
    }
  }
  
}

- (void)processCapturedFrames
{
  if (totalPreviousFrames > FRAMES_STORAGE_CAPACITY) {
    NSLog(@"Please increase FRAMES_STORAGE_CAPACITY to handle this amount of frames for an individual segment %i", totalPreviousFrames);
    return;
  }

  FramesStorage *framesToExport = [[FramesStorage alloc] init];
  NSMutableArray *metadataToExport = [[NSMutableArray alloc] init];
  int meaningfulFrames = 0;

  long ringBufferIndex = framesIndex > totalPreviousFrames ?
    framesIndex - totalPreviousFrames :
    FRAMES_STORAGE_CAPACITY - (totalPreviousFrames - framesIndex);
  
  // throw away last frames, because they are same
  // except the very last one
  // totalPreviousFrames = totalPreviousFrames - PAUSE_THRESHOLD + 1;
  while (totalPreviousFrames > 0) {
    FrameWithMetadata *frame = [framesStorage objectAtIndex:ringBufferIndex];
    NSDictionary *frameMetadata = @{
                                    @"touch": @(frame.touch),
                                    @"diff": @(frame.diff),
                                    @"time": @(frame.timestamp),
                                    };
    
    ringBufferIndex++;
    if (ringBufferIndex >= FRAMES_STORAGE_CAPACITY) {
      ringBufferIndex = 0;
    }
    totalPreviousFrames--;
    [framesToExport addFrame:frame];
    [metadataToExport addObject:frameMetadata];
    if (frame.touch > 0 || frame.diff) {
      meaningfulFrames++;
    }
  }
  
  if (framesToExport.count < PAUSE_THRESHOLD) {
    // empty segment
    return;
  }
  if (meaningfulFrames < framesToExport.count / 2) {
    // almost empty segment
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
