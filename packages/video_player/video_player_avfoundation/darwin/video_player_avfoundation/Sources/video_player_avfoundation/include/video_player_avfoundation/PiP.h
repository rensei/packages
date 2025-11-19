// FLTVideoPlayer+PiP.h
// Picture-in-Picture support for FLTVideoPlayer (iOS 16+).

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FLTVideoPlayer;

/// FLTVideoPlayer 向け Picture in Picture 拡張カテゴリ.
/// PiP を開始/終了するための API を追加します。
@interface FLTVideoPlayer (PictureInPicture) <AVPictureInPictureControllerDelegate>

/// この端末・OS で PiP が利用可能かどうか。
- (BOOL)isPictureInPictureSupported;

/// 現在 PiP がアクティブかどうか。
- (BOOL)isPictureInPictureActive;

/// PiP を開始する。
- (void)startPictureInPicture;

/// PiP を終了する。
- (void)stopPictureInPicture;

@end

NS_ASSUME_NONNULL_END
