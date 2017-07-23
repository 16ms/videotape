//
//  ImageProcessing.m
//  avfoundationtest
//
//  Created by Dmitriy L on 3/2/17.
//  Copyright © 2017 frontendy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "ImageProcessing.h"
#import "CEMovieMaker.h"
#include "math.h"

typedef union {
    uint32_t raw;
    unsigned char bytes[4];
    struct {
        char red;
        char green;
        char blue;
        char alpha;
    } __attribute__ ((packed)) pixels;
} FBComparePixel;

@implementation ImageProcessing

+ (NSImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
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
    NSLog(@"Can't do cgimage based on this sample buffer");
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

+ (BOOL)compareBitmaps:(NSBitmapImageRep *)image referenceImage:(NSBitmapImageRep *)referenceImage
{
  // Original code is copyright by Facebook
  NSAssert(CGSizeEqualToSize(image.size, referenceImage.size), @"Images must be same size.");
  
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
  
  imageEqual = (memcmp(referenceImagePixels, imagePixels, referenceImageSizeBytes) == 0);
  
  free(referenceImagePixels);
  free(imagePixels);
  
  return imageEqual;
}

+ (NSBitmapImageRep *)diffImage:(NSBitmapImageRep *)image referenceImage:(NSBitmapImageRep *)referenceImage
{
    
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
        return nil;
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
        return nil;
    }
    
    CGContextDrawImage(referenceImageContext, CGRectMake(0, 0, referenceImageSize.width, referenceImageSize.height), referenceImage.CGImage);
    CGContextDrawImage(imageContext, CGRectMake(0, 0, imageSize.width, imageSize.height), image.CGImage);
    
    CGContextRelease(referenceImageContext);
    CGContextRelease(imageContext);
    
   
    // Go through each pixel in turn and see if it is different
    const NSInteger pixelCount = referenceImageSize.width * referenceImageSize.height;
    
    FBComparePixel *p1 = referenceImagePixels;
    FBComparePixel *p2 = imagePixels;
    
    uint32_t *pixels = calloc(1, referenceImageSizeBytes);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 imageSize.width,
                                                 imageSize.height, CGImageGetBitsPerComponent(image.CGImage),
                                                 minBytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast );
    
    uint8_t *bufptr = (uint8_t *)pixels;
    for (int n = 0; n < pixelCount; ++n) {
        if (p1->raw != p2->raw) {
            bufptr[0] = 255;
            bufptr[1] = 155; // p1->pixels.green * 2;
            bufptr[2] = p1->pixels.blue;
            bufptr[3] = p1->pixels.alpha;

        } else {
            bufptr[0] = p1->pixels.red;
            bufptr[1] = p1->pixels.green;
            bufptr[2] = p1->pixels.blue;
            bufptr[3] = p1->pixels.alpha;
        }
        bufptr += 4;
        p1++;
        p2++;
    }
    
    CGImageRef newCGImage = CGBitmapContextCreateImage( context );
    CGContextRelease( context );
    CGColorSpaceRelease( colorSpace );
    free( pixels );
    free(referenceImagePixels);
    free(imagePixels);
    
    return [[NSBitmapImageRep alloc] initWithCGImage:newCGImage];
}

+ (NSBitmapImageRep *)calculateDiff:(NSBitmapImageRep *)image withOtherImage:(NSBitmapImageRep *)otherImage
{
    long width = [image pixelsWide];
    long height = [image pixelsHigh];
    // NSColor *highlightColor = [NSColor colorWithDeviceRed:1.0 green:0.54 blue:0.569 alpha:0.7];

    NSColor *color1, *color2;
    for (long i = 0; i< width; i++) {
        for (long j = 0; j < height; j++) {
            color1 = [image colorAtX:i y:j];
            color2 = [otherImage colorAtX:i y:j];
            if ([color1 isEqual:color2]) {
                // 255, 145, 54 100, 56.9, 21.2
                color1 = [color1 colorWithAlphaComponent:0.3];
                color1 = [NSColor colorWithDeviceRed:1.0 - color1.redComponent
                                      green:1.0 - color1.greenComponent
                                       blue:1.0 - color1.blueComponent
                                      alpha:1.0];
                [image setColor:color1 atX:i y:j];
            }
        }
    }
    return image;
}


+ (void)createMovie:(FramesStorage *)framesToExport withCompletion:(ImageProcessingMovieCompletion)completion;
{
    FramesStorage *tempFrames = [[FramesStorage alloc] init];
    
    NSSize size = framesToExport.size;
    long width = size.width;
    
    while (width % 16 != 0) {
        width--;
    }
    NSDictionary *settings = [CEMovieMaker videoSettingsWithCodec:AVVideoCodecH264
                                                        withWidth:width andHeight:size.height];
    // float timestamp = [[NSDate date] timeIntervalSince1970];
    NSURL *urlToWrite = [[self applicationDataDirectory]
                         URLByAppendingPathComponent:
                         [NSString stringWithFormat:@"%f_movie.mov", [framesToExport objectAtIndex:0].timestamp]];
    
    CEMovieMaker *movieMaker = [[CEMovieMaker alloc]
                                initWithSettings:settings
                                withURL:urlToWrite withFPS:FPS_INPUT];
    
    for (NSInteger i = 0; i < framesToExport.count; i++) {
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                                 initWithBitmapDataPlanes:NULL
                                 pixelsWide:size.width
                                 pixelsHigh:size.height
                                 bitsPerSample:8
                                 samplesPerPixel:4
                                 hasAlpha:YES
                                 isPlanar:NO
                                 colorSpaceName:NSDeviceRGBColorSpace
                                 bytesPerRow:0
                                 bitsPerPixel:0];
        rep.size = size;
      
        FrameWithMetadata *frame = [framesToExport objectAtIndex:i];
      
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:
        [NSGraphicsContext graphicsContextWithBitmapImageRep:rep]];
        
        [[framesToExport objectAtIndex:i].image drawAtPoint:NSMakePoint(0, 0)
                     fromRect:NSZeroRect
                    operation:NSCompositingOperationSourceOver
                     fraction:1.0];
        
        if ([framesToExport objectAtIndex:i].touch == 1) {
            NSPoint point = [framesToExport objectAtIndex:i].touchLocation;
            [self drawTouchPoint:point.x y:point.y * 2 radius:size.width / 5];
        }
       
        [NSGraphicsContext restoreGraphicsState];
      
      
        NSImage *image = [[NSImage alloc] init];
        [image addRepresentation:rep];
        frame.image = image;
       // [tempFrames addObject:frame];
      
        [tempFrames updateFrame:frame index:i];
    }
 
  [movieMaker createMovieFromFrames:tempFrames withCompletion:completion];
}

+(BOOL) writeCGImage:(CGImageRef) image path:(NSString *) path
{
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    if (!destination) {
        NSLog(@"Failed to create CGImageDestination for %@", path);
        return NO;
    }
    CGImageDestinationAddImage(destination, image, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
        CFRelease(destination);
        return NO;
    }
    
    CFRelease(destination);
    return YES;
}

+(void)drawTouchPoint:(CGFloat)x y:(CGFloat)y radius:(CGFloat)radius
{
    NSRect rect = NSMakeRect(x + radius / 2, y - radius / 2, radius, radius);
    NSBezierPath* circlePath = [NSBezierPath bezierPath];
    [circlePath appendBezierPathWithOvalInRect: rect];
    [[NSColor colorWithSRGBRed:0.5 green:0.5 blue:0.5 alpha:0.7] setStroke];
    [[NSColor colorWithSRGBRed:0.5 green:0.5 blue:0.5 alpha:0.25] setFill];
    [circlePath stroke];
    [circlePath fill];
}

+(void)drawRectangle:(NSRect)rect color:(NSColor *)color
{
    // NSRect r = NSMakeRect(10, 10, 50, 60);
    NSBezierPath *bp = [NSBezierPath bezierPathWithRect:rect];
    // NSColor *color = [NSColor blueColor];
    [color set];
    [bp setLineWidth:3.0];
    [bp stroke];
}

+(void)drawTextAtPoint:(CGFloat)x y:(CGFloat)y text:(NSString *)text color:(NSColor *)color
{
    NSDictionary *attributes = @{
                                 NSFontAttributeName: [NSFont boldSystemFontOfSize:30],
                                 NSForegroundColorAttributeName: color};
    [text drawAtPoint:NSMakePoint(x, y) withAttributes:attributes];
}

+ (NSString *)saveDiffCanvasIntoFile:(FramesStorage *)framesToExport
{
    long onX = framesToExport.count < 8 ? 3 : framesToExport.count / sqrt(1.3 * framesToExport.count);// < 30 ? 5 : 7;
    long onY = framesToExport.count / onX;
    CGSize size = [framesToExport size];
    long pieceWidth = size.width;
    long pieceHeight = size.height;
    
    //    // long height = width * images[0].size.width / images[0].size.height;
    NSLog(@"imagesCount: %li sourcewidth: %f onX: %li onY: %li totalWidth: %li totalHeight: %li",
          framesToExport.count,
          size.width,
          onX, onY,
          pieceWidth * onX, pieceHeight * onY);
    // calculate each image height
    
    // before draw the image, calculate diff with previous ones
    NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(pieceWidth * onX,
                                                                 pieceHeight * onY)];
    
    [newImage lockFocus];
    // CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    for (int i = 0; i < onY; i++) {
        for (int j = 0; j < onX; j++) {
            long index = i * onX + j;
            if (index < framesToExport.count - 1) {
                FrameWithMetadata *frame = [framesToExport objectAtIndex:index];

                NSImage *image = frame.image;
                NSBitmapImageRep *rep;
                if (index > 1) {
                    rep = [self diffImage:(NSBitmapImageRep *)image.representations[0]
                           referenceImage:( NSBitmapImageRep *)[framesToExport objectAtIndex:index - 1].image.representations[0]];
                
                } else {
                    rep = (NSBitmapImageRep *)image.representations[0];
                }
                if (!rep) {
                    // TODO: more proper way to handle this
                    return nil;
                }
                long x = pieceWidth * j;
                long y = pieceHeight * (onY - i - 1);
              
                [rep drawInRect:NSMakeRect(x, y, pieceWidth, pieceHeight)];
                if (frame.touch == 1) {
                    NSLog(@" index: %i %i %li %lu %f %f",
                          i,
                          j, index, (unsigned long)frame.touch,
                          frame.touchLocation.x,
                          frame.touchLocation.y);
                  [self drawTouchPoint:x + frame.touchLocation.x y: y + frame.touchLocation.y * 2 radius:pieceWidth / 5];
                }
                //NSString *text = [NSString stringWithFormat:@"%li", index];
                //NSColor* color = frame.differ ? [NSColor greenColor] : [NSColor redColor];
                //[self drawTextAtPoint:x + 100 y: y + 100 text:text color:color];
                //[self drawRectangle:NSMakeRect(x, y, pieceWidth, pieceHeight)
                //              color:frame.differ ? [NSColor greenColor] : [NSColor redColor]];
            }
            
        }
    }
    
    [newImage unlockFocus];
    
    if ([newImage representations].count > 0) {
        
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                                 initWithBitmapDataPlanes:NULL
                                 pixelsWide:newImage.size.width
                                 pixelsHigh:newImage.size.height
                                 bitsPerSample:8
                                 samplesPerPixel:4
                                 hasAlpha:YES
                                 isPlanar:NO
                                 colorSpaceName:NSDeviceRGBColorSpace
                                 bytesPerRow:0
                                 bitsPerPixel:0];
        rep.size = newImage.size;

        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:
        [NSGraphicsContext graphicsContextWithBitmapImageRep:rep]];

        [newImage drawAtPoint:NSMakePoint(0, 0)
                 fromRect:NSZeroRect
                operation:NSCompositingOperationSourceOver
                 fraction:1.0];

        [NSGraphicsContext restoreGraphicsState];
        NSData *data = [rep representationUsingType: NSPNGFileType properties: @{}];
        NSURL *urlToWrite = [[self applicationDataDirectory]
                             URLByAppendingPathComponent:[NSString
                                                          stringWithFormat:@"%f_canvas.png", [[NSDate date] timeIntervalSince1970]]];
        
        [data writeToURL:urlToWrite atomically: NO];
        NSLog(@"snapshot canvas written to %@", urlToWrite.absoluteString);
        return urlToWrite.absoluteString;
    }
    
    return nil;
}

+ (NSURL*)applicationDataDirectory {
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    NSArray* possibleURLs = [sharedFM URLsForDirectory:NSApplicationSupportDirectory
                                             inDomains:NSUserDomainMask];
    NSURL* appSupportDir = nil;
    NSURL* appDirectory = nil;
    
    if ([possibleURLs count] >= 1) {
        // Use the first directory (if multiple are returned)
        appSupportDir = [possibleURLs objectAtIndex:0];
    }
    
    // If a valid app support directory exists, add the
    // app's bundle ID to it to specify the final directory.
    if (appSupportDir) {
        NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
        appDirectory = [appSupportDir URLByAppendingPathComponent:appBundleID];
    }
    
    return appDirectory;
}


@end
