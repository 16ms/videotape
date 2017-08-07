//
//  VideoTapeTesterUITests.m
//  VideoTapeTesterUITests
//
//  Created by Dmitriy L on 6/14/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "VideoTapeManager.h"

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
    [VideoTapeManager stopCapturing];
    [super tearDown];
}

- (void)testNavigationTransition
{
  float score = 0.0;
  sleep(0.5);
  [VideoTapeManager startCapturing];
  XCUIApplication *app = [[XCUIApplication alloc] init];
  XCUIElement *chatWithLucyButton = app.buttons[@"Chat with Lucy"];
  [chatWithLucyButton tap];
//  [VideoTapeManager recordTouch:[chatWithLucyButton coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.0)].screenPoint];
//  
  sleep(1);
  ;
  score = [VideoTapeManager getLastSegmentScore];
  XCTAssertGreaterThan(score, TARGET_SCORE);
  sleep(2);
//  [VideoTapeManager
//      recordTouch:[app.buttons[@"header-back"]
//                      coordinateWithNormalizedOffset:CGVectorMake(0.0, 0.0)]
//                      .screenPoint];
  [app.buttons[@"header-back"] tap];
  sleep(1);
  score = [VideoTapeManager getLastSegmentScore];
  XCTAssertGreaterThan(score, TARGET_SCORE);
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




@end
