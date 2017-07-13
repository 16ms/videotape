//
//  CEMovieMaker.m
//  CEMovieMaker
//
//  Created by Cameron Ehrlich on 9/17/14.
//  Copyright (c) 2014 Cameron Ehrlich. All rights reserved.
//

#import "CEMovieMaker.h"

typedef NSImage*(^CEMovieMakerNSImageExtractor)(NSObject* inputObject);

@implementation CEMovieMaker

- (instancetype)initWithSettings:(NSDictionary *)videoSettings withURL:(NSURL *)fileURL withFPS:(int)fps;
{
    self = [self init];
    if (self) {
        NSError *error;
        
        _fileURL = fileURL;
        _assetWriter = [[AVAssetWriter alloc] initWithURL:self.fileURL
                                                 fileType:AVFileTypeQuickTimeMovie error:&error];
        if (error) {
            NSLog(@"Error: %@", error.debugDescription);
        }
        NSParameterAssert(self.assetWriter);
        
        _videoSettings = videoSettings;
        _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                          outputSettings:videoSettings];
        // _writerInput.mediaTimeScale = fps;
        NSParameterAssert(self.writerInput);
        NSParameterAssert([self.assetWriter canAddInput:self.writerInput]);
        
        [self.assetWriter addInput:self.writerInput];
        
        NSDictionary *bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
        
        _bufferAdapter = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.writerInput sourcePixelBufferAttributes:bufferAttributes];
        _frameTime = CMTimeMake(1, fps);
    }
    return self;
}

//- (void) createMovieFromImageURLs:(NSArray CE_GENERIC_URL*)urls withCompletion:(CEMovieMakerCompletion)completion;
//{
//    [self createMovieFromSource:urls extractor:^NSImage *(NSObject *inputObject) {
//        return [UIImage imageWithData: [NSData dataWithContentsOfURL:((NSURL*)inputObject)]];
//    } withCompletion:completion];
//}

- (void) createMovieFromImages:(NSArray CE_GENERIC_IMAGE *)images withCompletion:(CEMovieMakerCompletion)completion;
{
    [self createMovieFromSource:images extractor:^NSImage *(NSObject *inputObject) {
        return (NSImage*)inputObject;
    } withCompletion:completion];
}

- (void) createMovieFromSource:(NSArray *)images extractor:(CEMovieMakerNSImageExtractor)extractor withCompletion:(CEMovieMakerCompletion)completion;
{
    self.completionBlock = completion;
    
    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    
    __block NSInteger i = 0;
    
    NSInteger frameNumber = [images count];
    
    [self.writerInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:^{
        while (YES) {
            if (i >= frameNumber) {
                break;
            }
            if ([self.writerInput isReadyForMoreMediaData]) {
                
                CVPixelBufferRef sampleBuffer;
                @autoreleasepool {
                    NSImage* img = extractor([images objectAtIndex:i]);
                    if (img == nil) {
                        i++;
                        NSLog(@"Warning: could not extract one of the frames");
                        continue;
                    }
                    NSRect imageRect = NSMakeRect(0, 0, img.size.width, img.size.height);
                    
                    CGImageRef cgImage = [img CGImageForProposedRect:&imageRect context:NULL hints:nil];

                    sampleBuffer = [self newPixelBufferFromCGImage:cgImage];
                }
                if (sampleBuffer) {
                    if (i == 0) {
                        [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:kCMTimeZero];
                    }else{
                        CMTime lastTime = CMTimeMake(i - 1, self.frameTime.timescale);
                        CMTime presentTime = CMTimeAdd(lastTime, self.frameTime);
                        BOOL res = [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:presentTime];
                        if (!res) {
                            NSLog(@"Error: assetWriter.status %i", self.assetWriter.status);
                        }
                    }
                    CFRelease(sampleBuffer);
                    i++;
                }
            }
        }
        
        [self.writerInput markAsFinished];
        [self.assetWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionBlock(self.fileURL);
            });
        }];
        
        CVPixelBufferPoolRelease(self.bufferAdapter.pixelBufferPool);
    }];
}


- (CVPixelBufferRef)newPixelBufferFromCGImage:(CGImageRef)image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = [[self.videoSettings objectForKey:AVVideoWidthKey] floatValue];
    CGFloat frameHeight = [[self.videoSettings objectForKey:AVVideoHeightKey] floatValue];
    
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 4 * frameWidth,
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           CGImageGetWidth(image),
                                           CGImageGetHeight(image)),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (NSDictionary *)videoSettingsWithCodec:(NSString *)codec withWidth:(CGFloat)width andHeight:(CGFloat)height
{
    
    if ((int)width % 16 != 0 ) {
        NSLog(@"Warning: video settings width must be divisible by 16.");
    }
    
    NSDictionary *videoSettings = @{AVVideoCodecKey : codec,
                                    AVVideoWidthKey : [NSNumber numberWithInt:(int)width],
                                    AVVideoHeightKey : [NSNumber numberWithInt:(int)height]
                                    };
    
    return videoSettings;
}

@end
