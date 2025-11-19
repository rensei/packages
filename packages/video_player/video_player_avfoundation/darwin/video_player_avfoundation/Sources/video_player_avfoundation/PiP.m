// FLTVideoPlayer+PiP.m
// Picture-in-Picture support implementation for FLTVideoPlayer (iOS 16+).

#import "./include/video_player_avfoundation/PiP.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/// 元の FLTVideoPlayer が持っている player プロパティだけ再宣言しておく。
/// （実体はオリジナル側にあるので、ここでは interface のみ）
@interface FLTVideoPlayer ()
@property(readonly, nonatomic) AVPlayer *player;
@end

// Associated object のキー
static const void *kFvpPipLayerKey = &kFvpPipLayerKey;
static const void *kFvpPipControllerKey = &kFvpPipControllerKey;

@interface FLTVideoPlayer (PiPPrivate)

@property (nonatomic, strong, nullable) AVPlayerLayer *fvp_pipLayer;
@property (nonatomic, strong, nullable) AVPictureInPictureController *fvp_pipController;

@end

@implementation FLTVideoPlayer (PiPPrivate)

- (void)setFvp_pipLayer:(AVPlayerLayer * _Nullable)layer {
  objc_setAssociatedObject(self, kFvpPipLayerKey, layer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AVPlayerLayer *)fvp_pipLayer {
  return objc_getAssociatedObject(self, kFvpPipLayerKey);
}

- (void)setFvp_pipController:(AVPictureInPictureController * _Nullable)controller {
  objc_setAssociatedObject(self, kFvpPipControllerKey, controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AVPictureInPictureController *)fvp_pipController {
  return objc_getAssociatedObject(self, kFvpPipControllerKey);
}

@end

@implementation FLTVideoPlayer (PictureInPicture)

#pragma mark - Public API

- (BOOL)isPictureInPictureSupported {
  // iOS 16+ 前提だが、一応サポート有無だけはチェックしておく
  return [AVPictureInPictureController isPictureInPictureSupported];
}

- (BOOL)isPictureInPictureActive {
  AVPictureInPictureController *controller = self.fvp_pipController;
  return controller.isPictureInPictureActive;
}

- (void)startPictureInPicture {
  if (![self fvp_isPictureInPictureSupported]) {
    return;
  }

  // まだ PiP 用の layer/controller が無ければ作る
  if (!self.fvp_pipController) {
    [self fvp_configurePictureInPictureObjectsIfNeeded];
  }

  AVPictureInPictureController *controller = self.fvp_pipController;
  if (!controller) {
    return;
  }

  if (!controller.isPictureInPicturePossible) {
    // 動画がまだ初期化されていないなどで PiP 不可なことがある
    return;
  }

  if (!controller.isPictureInPictureActive) {
    [controller startPictureInPicture];
  }
}

- (void)stopPictureInPicture {
  AVPictureInPictureController *controller = self.fvp_pipController;
  if (controller.isPictureInPictureActive) {
    [controller stopPictureInPicture];
  }
}

#pragma mark - Internal setup

- (void)fvp_configurePictureInPictureObjectsIfNeeded {
  if (self.fvp_pipController != nil) {
    return;
  }

  // AVPlayerLayer を PiP 用に作成（画面には追加しない）
  AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];

  // 何かしらサイズがないと PiP が動かないことがあるので、適当なサイズを入れておく
  UIScreen *screen = UIScreen.mainScreen;
  layer.frame = CGRectMake(0, 0, screen.bounds.size.width, screen.bounds.size.height);

  self.fvp_pipLayer = layer;

  // iOS 15+ では class method 版が使えるのでこちらを使う（16+でももちろんOK）
  AVPictureInPictureController *controller =
    [AVPictureInPictureController pictureInPictureControllerWithPlayerLayer:layer];

  controller.delegate = self;
  self.fvp_pipController = controller;
}

#pragma mark - AVPictureInPictureControllerDelegate

- (void)pictureInPictureControllerWillStartPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  // 必要ならここで何か（例: ログ、内部状態更新など）
}

- (void)pictureInPictureControllerDidStartPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  // Dart 側にイベントを飛ばしたい場合は、
  // FLTVideoPlayerPlugin 側の eventSink を呼ぶ形にしてもよい。
}

- (void)pictureInPictureControllerWillStopPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  // PiP 終了直前に呼ばれる
}

- (void)pictureInPictureControllerDidStopPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  // PiP 完了後の後処理があればここで
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:
        (void (^)(BOOL restored))completionHandler {

  // アプリの UI を前面に戻すタイミング。
  // Flutter 側で既に UI を表示済みとみなして YES 返すだけのシンプル実装。
  dispatch_async(dispatch_get_main_queue(), ^{
    completionHandler(YES);
  });
}

@end

NS_ASSUME_NONNULL_END
