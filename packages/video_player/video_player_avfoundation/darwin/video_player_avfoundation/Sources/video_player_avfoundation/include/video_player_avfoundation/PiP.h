// PiP.h
// video_player_avfoundation – iOS PiP helper

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>

@class FVPVideoPlayer;

NS_ASSUME_NONNULL_BEGIN

@interface PiP : NSObject <AVPictureInPictureControllerDelegate>

+ (instancetype)sharedInstance;

@property(nonatomic, weak, readonly, nullable) FVPVideoPlayer *currentPlayer;
@property(nonatomic, strong, readonly, nullable) AVPictureInPictureController *pipController;

@property(nonatomic, readonly) BOOL isPiPAvailable;
@property(nonatomic, readonly) BOOL isPiPActive;

/// FVPVideoPlayer（platform view / texture どちらでも）を紐付ける
- (void)attachToPlayer:(FVPVideoPlayer *)player;
- (void)detachCurrentPlayer;

/// PiP 開始・終了
- (void)startPiP;
- (void)stopPiP;

@end

NS_ASSUME_NONNULL_END
