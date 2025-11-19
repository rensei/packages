// PiP.m
// video_player_avfoundation – iOS PiP helper

#import "PiP.h"
#import "FVPVideoPlayer.h"

@interface PiP ()

@property(nonatomic, weak, readwrite, nullable) FVPVideoPlayer *currentPlayer;
@property(nonatomic, strong) AVPlayerLayer *pipLayer;
@property(nonatomic, strong, readwrite, nullable) AVPictureInPictureController *pipController;

@end

@implementation PiP

+ (instancetype)sharedInstance {
  static PiP *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[PiP alloc] init];
  });
  return instance;
}

- (BOOL)isPiPAvailable {
  return [AVPictureInPictureController isPictureInPictureSupported];
}

- (BOOL)isPiPActive {
  return self.pipController.isPictureInPictureActive;
}

- (void)attachToPlayer:(FVPVideoPlayer *)player {
  if (!player) {
    return;
  }
  self.currentPlayer = player;
  [self configureControllerForCurrentPlayer];
}

- (void)detachCurrentPlayer {
  if (self.isPiPActive) {
    [self stopPiP];
  }
  self.currentPlayer = nil;
  self.pipController = nil;
  self.pipLayer = nil;
}

- (void)configureControllerForCurrentPlayer {
  if (!self.currentPlayer) {
    return;
  }

  AVPlayer *player = self.currentPlayer.player;
  if (!player) {
    return;
  }

  // PiP 用の AVPlayerLayer を自前で管理する
  if (self.pipLayer == nil) {
    self.pipLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    self.pipLayer.videoGravity = AVLayerVideoGravityResizeAspect;
  } else {
    self.pipLayer.player = player;
  }

  AVPictureInPictureControllerContentSource *contentSource =
      [[AVPictureInPictureControllerContentSource alloc] initWithPlayerLayer:self.pipLayer];

  self.pipController =
      [[AVPictureInPictureController alloc] initWithContentSource:contentSource];
  self.pipController.delegate = self;
}

- (void)startPiP {
  if (!self.currentPlayer) {
    return;
  }
  if (!self.pipController) {
    [self configureControllerForCurrentPlayer];
  }
  if (!self.pipController || !self.pipController.isPictureInPicturePossible) {
    return;
  }
  if (!self.pipController.isPictureInPictureActive) {
    [self.pipController startPictureInPicture];
  }
}

- (void)stopPiP {
  if (self.pipController.isPictureInPictureActive) {
    [self.pipController stopPictureInPicture];
  }
}

#pragma mark - AVPictureInPictureControllerDelegate

- (void)pictureInPictureControllerDidStartPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  // 必要ならここでイベントを飛ばす
}

- (void)pictureInPictureControllerDidStopPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  // 必要ならここでイベントを飛ばす
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController
restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:
    (void (^)(BOOL restored))completionHandler {
  // Flutter 側で UI を復元するので、ここでは NO を返して完了だけ知らせる
  if (completionHandler) {
    completionHandler(NO);
  }
}

@end
