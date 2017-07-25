//
//  VideoTapeTesterUITests.m
//  VideoTapeTesterUITests
//
//  Created by Dmitriy L on 6/14/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>

#define TARGET_SCORE 0.75

@interface VideoTapeTesterUITests : XCTestCase

@end

@implementation VideoTapeTesterUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    sleep(2);
    [self videotape:@{@"type": @"STOP_CAPTURING"} checkAnswer:NO];
    [super tearDown];
}

- (void)testNavigationTransition
{
  sleep(1);
  [self videotape:@{@"type": @"START_CAPTURING"} checkAnswer:NO];
  XCUIApplication *app = [[XCUIApplication alloc] init];
  XCUIElement *chatWithLucyButton = app.buttons[@"Chat with Lucy"];
  [chatWithLucyButton tap];
  [self recordTouch:[chatWithLucyButton coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.0)]];
  
  sleep(1);
  [self videotape:@{@"type": @"GET_LAST_SEGMENT"} checkAnswer:YES];
  sleep(2);
  [self recordTouch:[app.buttons[@"header-back"] coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.0)]];
  [app.buttons[@"header-back"] tap];
  sleep(1);
  [self videotape:@{@"type": @"GET_LAST_SEGMENT"} checkAnswer:YES];
//  [chatWithLucyButton tap];
//  [self videotape:@{@"type": @"GET_LAST_SEGMENT"} checkAnswer:YES];
//  
//  XCUIElement *chatWithLucyElement = [app.otherElements[@"Hello, Chat App! Chat with Lucy Chat with Lucy"] childrenMatchingType:XCUIElementTypeOther][@"Chat with Lucy"];
//
//  XCUICoordinate *leftPoint = [chatWithLucyElement coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.0)];
//  XCUICoordinate *rightPoint = [[chatWithLucyElement coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.0)] coordinateWithOffset:CGVectorMake(300.0, 0.0)];
//  [leftPoint pressForDuration:0.5 thenDragToCoordinate:rightPoint];
//  [self videotape:@{@"type": @"GET_LAST_SEGMENT"} checkAnswer:YES];

}

-(void)recordTouch:(XCUICoordinate *)coordinate
{
  [self videotape:@{
    @"type" : @"RECORD_TOUCH_EVENT",
    @"event" : @[ @{
      @"x" : @(coordinate.screenPoint.x),
      @"y" : @(coordinate.screenPoint.y),
      @"timestamp" : @([NSDate date].timeIntervalSince1970 * 1000)
    } ]
  }
      checkAnswer:NO];
}

-(void)recordTouch:(XCUICoordinate *)startCoordinate endCoordinate:(XCUICoordinate *)endCoordinate duration:(NSTimeInterval)duration
{
  [self videotape:@{@"type": @"RECORD_TOUCH_EVENT", @"event": @[]} checkAnswer:YES];
}

-(void)videotape:(NSDictionary *)payload checkAnswer:(BOOL)checkAnswer
{
  NSLog(@"videotape http request: %@", payload);
  NSError *error;
  NSData *postData = [NSJSONSerialization dataWithJSONObject:payload
                                                     options:(NSJSONWritingOptions)    (NSJSONWritingPrettyPrinted)
                                                       error:&error];
  
  NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setURL:[NSURL URLWithString:@"http://localhost:5561"]];
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
          XCTAssertNil(error, @"Http request to videotape should be null");
          if (checkAnswer) {
            XCTAssertNotNil(data, @"Response should not be null");
            error = nil;
            if (data) {
              result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
              XCTAssertNil(error, @"HTTPResult should be valid json");
            }
          }
          dispatch_semaphore_signal(sem);
        }];
  [task resume];
  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
  if (checkAnswer) {
    XCTAssertNotNil(result[@"score"]);
    NSLog(@"result: %@", result);
    XCTAssert([result[@"score"] floatValue] > TARGET_SCORE,
              @"Score is %f, TARGET_SCORE=%f, details %@",
              [result[@"score"] floatValue], TARGET_SCORE, result[@"scoreDetails"] );
  }
  return;
}

@end
