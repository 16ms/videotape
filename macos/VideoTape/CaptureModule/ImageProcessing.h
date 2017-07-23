//
//  ImageProcessing.h
//  avfoundationtest
//
//  Created by Dmitriy L on 3/2/17.
//  Copyright © 2017 frontendy. All rights reserved.
//
#define MAX_HEIGHT 1900 * 2
#define MAX_WIDTH 1300 * 2
#define FPS_INPUT 60
#define FRAMES_STORAGE_BUFFER_IN_SECONDS 3
#define FRAMES_STORAGE_CAPACITY FPS_INPUT * FRAMES_STORAGE_BUFFER_IN_SECONDS
#define PAUSE_THRESHOLD 4
#define CAPTURE_THRESHOLD PAUSE_THRESHOLD + 1

#import "FramesStorage.h"

typedef void(^ImageProcessingMovieCompletion)(NSURL *fileURL);

@interface ImageProcessing : NSObject

+ (NSImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;
+ (BOOL)compareBitmaps:(NSBitmapImageRep *)image referenceImage:(NSBitmapImageRep *)referenceImage;
+ (NSString *)saveDiffCanvasIntoFile:(FramesStorage *)framesToExport;
+ (void)createMovie:(FramesStorage *)framesToExport withCompletion:(ImageProcessingMovieCompletion)completion;

@end
