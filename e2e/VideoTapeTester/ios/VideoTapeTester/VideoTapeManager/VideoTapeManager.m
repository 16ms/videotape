#import "VideoTapeManager.h"
#define VIDEOTAPE_SERVER @"http://localhost:5561"

@implementation InterceptingUIWindow

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        
    }
    return self;
}

- (void)sendEvent:(UIEvent *)event
{
    // if (self.active)
    // {
        NSSet *allTouches = [event allTouches];

        for (UITouch *touch in [allTouches allObjects])
        {
            switch (touch.phase)
            {
                case UITouchPhaseBegan:
                case UITouchPhaseMoved:
                case UITouchPhaseStationary:
                {
                  NSLog(@"TOUCH!");
                  [VideoTapeManager recordTouch:[touch locationInView:nil]];
                  break;
                }

                case UITouchPhaseEnded:
                case UITouchPhaseCancelled:
                {
                    // [self removeFingerTipWithHash:touch.hash animated:YES];
                    break;
                }
            }
        }
    // }

    [super sendEvent:event];

    // [self scheduleFingerTipRemoval]; // We may not see all UITouchPhaseEnded/UITouchPhaseCancelled events.
}

@end

@implementation VideoTapeManager

+ (void)startCapturing
{
  [self videotapeAction:@{@"type": @"START_CAPTURING"} parseResponse:NO];
}

+ (void)stopCapturing
{
  [self videotapeAction:@{@"type": @"STOP_CAPTURING"} parseResponse:NO];
}

+ (NSDictionary *)videotapeAction:(NSDictionary *)payload parseResponse:(BOOL)parseResponse
{
  NSLog(@"sending the request... %@", payload);
  NSError *error;
  NSData *postData = [NSJSONSerialization dataWithJSONObject:payload
                                                     options:(NSJSONWritingOptions)    (NSJSONWritingPrettyPrinted)
                                                       error:&error];
  
  NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setURL:[NSURL URLWithString:VIDEOTAPE_SERVER]];
  [request setHTTPMethod:@"POST"];
  [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  [request setHTTPBody:postData];
  dispatch_semaphore_t    sem =  dispatch_semaphore_create(0);
  NSDictionary __block *result = nil;
  NSURLSessionDataTask *task = [[NSURLSession sharedSession]
                                dataTaskWithRequest:request
                                completionHandler:^(NSData *data, NSURLResponse *response,
                                                    NSError *error) {
                                  NSAssert(error == nil, @"Http request to videotape should be null");
                                  if (parseResponse) {
                                    
                                    error = nil;
                                    if (data) {
                                      result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                                      
                                    }
                                  }
                                  dispatch_semaphore_signal(sem);
                                }];
  [task resume];
  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
  if (parseResponse) {
    NSLog(@"result: %@", result);
    return result;
  }
  return nil;
}

+(NSDictionary *)getLastSegment
{
  return [VideoTapeManager videotapeAction:@{@"type": @"GET_LAST_SEGMENT"} parseResponse:YES];
}

+(float)getLastSegmentScore
{
  NSDictionary *result = [VideoTapeManager videotapeAction:@{@"type": @"GET_LAST_SEGMENT"} parseResponse:YES];
  if (result) {
    return [result[@"score"] floatValue];
  }
  return 0.0;
}

+(void)recordTouch:(CGPoint)coordinate
{
  [VideoTapeManager videotapeAction:@{
                    @"type" : @"RECORD_TOUCH_EVENT",
                    @"event" : @[ @{
                                    @"x" : @(coordinate.x),
                                    @"y" : @(coordinate.y),
                                    @"timestamp" : @([NSDate timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970)
                                    } ]
                    }
      parseResponse:NO];
}

//+(void)recordTouch:(XCUICoordinate *)startCoordinate endCoordinate:(XCUICoordinate *)endCoordinate duration:(NSTimeInterval)duration
//{
//  [self videotape:@{@"type": @"RECORD_TOUCH_EVENT", @"event": @[]} checkAnswer:YES];
//}


@end
