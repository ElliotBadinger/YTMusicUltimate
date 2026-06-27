#import <UIKit/UIKit.h>
#import "YTPlayerResponse.h"

@interface YTPlayerViewController : UIViewController
// 'playerResponse' was removed in YouTube Music 9.17.2.
// 'contentPlayerResponse' is the replacement (confirmed present in 9.23.4 binary dump).
@property (nonatomic, assign, readonly) YTPlayerResponse *contentPlayerResponse;
@property (readonly, nonatomic) NSString *contentVideoID;
@property (nonatomic, assign, readonly) CGFloat currentVideoTotalMediaTime;
@property (nonatomic, strong) NSMutableDictionary *sponsorBlockValues;

- (void)seekToTime:(CGFloat)time;
- (NSString *)currentVideoID;
- (CGFloat)currentVideoMediaTime;
- (void)skipSegment;
@end
