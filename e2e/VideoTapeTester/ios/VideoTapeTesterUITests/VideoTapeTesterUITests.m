//
//  VideoTapeTesterUITests.m
//  VideoTapeTesterUITests
//
//  Created by Dmitriy L on 6/14/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>

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
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNavigationTransition
{
  [self videotape:@{@"type": @"START_CAPTURING"} checkAnswer:NO];
  XCUIApplication *app = [[XCUIApplication alloc] init];
  XCUIElement *chatWithLucyButton = app.buttons[@"Chat with Lucy"];
  [chatWithLucyButton tap];
  sleep(1);
  [self videotape:@{@"type": @"GET_LAST_SEGMENT"} checkAnswer:YES];
  
//  sleep(1);
//  [app.buttons[@"header-back"] tap];
//  [self videotape:@{@"type": @"GET_LAST_SEGMENT"} checkAnswer:YES];
//  [chatWithLucyButton tap];
//  [self videotape:@{@"type": @"GET_LAST_SEGMENT"} checkAnswer:YES];
//  
//  XCUIElement *chatWithLucyElement = [app.otherElements[@"Hello, Chat App! Chat with Lucy Chat with Lucy"] childrenMatchingType:XCUIElementTypeOther][@"Chat with Lucy"];
//
//  XCUICoordinate *leftPoint = [chatWithLucyElement coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.0)];
//  XCUICoordinate *rightPoint = [[chatWithLucyElement coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.0)] coordinateWithOffset:CGVectorMake(300.0, 0.0)];
//  [leftPoint pressForDuration:0.5 thenDragToCoordinate:rightPoint];
//  [self videotape:@{@"type": @"GET_LAST_SEGMENT"} checkAnswer:YES];

  [self videotape:@{@"type": @"STOP_CAPTURING"} checkAnswer:NO];
}

-(void)videotape:(NSDictionary *)payload checkAnswer:(BOOL)checkAnswer
{
  NSLog(@"videotape http request %@", payload);
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
  NSURLSessionDataTask *task = [[NSURLSession sharedSession]
      dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response,
                            NSError *error) {
          XCTAssertNil(error, @"Http request to videotape should be null");
          if (checkAnswer) {
            XCTAssertNotNil(data, @"Response should not be null");
            NSLog(@"data: %@", data);
            error = nil;
            if (data) {
              NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
              XCTAssertNil(error, @"Http request to videotape should be null");
              XCTAssertNotNil(dictionary[@"score"]);
              XCTAssert([dictionary[@"score"] floatValue] > 0.9);
            }
          }
    }];
  [task resume];
  sleep(0.3);
}

@end
