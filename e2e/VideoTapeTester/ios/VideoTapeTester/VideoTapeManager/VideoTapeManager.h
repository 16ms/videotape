#import <UIKit/UIKit.h>

@interface InterceptingUIWindow : UIWindow
@end

@interface VideoTapeManager : NSObject

+(void)startCapturing;
+(void)stopCapturing;
+(void)recordTouch:(CGPoint)coordinate;
+(NSDictionary *)getLastSegment;
+(float)getLastSegmentScore;

@end
