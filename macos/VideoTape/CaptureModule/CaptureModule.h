#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <React/RCTConvert.h>

typedef NS_ENUM(NSInteger, CapturingState) {
  CapturingInitialized = 0,
  CapturingStarted = 1,
  CapturingSegmentFound = 2,
  CapturingSegmentProcessed = 3,
  CapturingPaused = 4,
  CapturingError = 5,
};

@protocol VTCapturingProcessDelegate <NSObject>
- (void)onSettingsChange:(NSDictionary *_Nonnull)settings;
- (void)onCapturingStateChange:(CapturingState)capturingState body:(NSDictionary *_Nullable)body;
@end


@interface CaptureModule : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate>

@property (nonatomic) NSUInteger pid;
@property (nonatomic) BOOL capturing;
@property (nonatomic) NSMutableDictionary * _Nonnull settings;
@property (nullable, assign) id <VTCapturingProcessDelegate> delegate;

- (NSArray *_Nullable)windowList;
- (NSInteger)findPIDByAppName:(NSString*_Nonnull)appName;
- (void)mergeSettings:(NSDictionary*_Nonnull)newSettings;
- (BOOL)setTargetProcessByPID:(NSUInteger)pid;
- (void)start;
- (void)stop;

@end
