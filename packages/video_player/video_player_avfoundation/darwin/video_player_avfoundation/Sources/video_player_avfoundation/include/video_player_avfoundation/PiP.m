// PiP.m
// video_player_avfoundation – iOS PiP helper

#import "PiP.h"
#import "FVPVideoPlayer.h"
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>

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
  BOOL supported = [AVPictureInPictureController isPictureInPictureSupported];
  NSLog(@"[PiP] isPiPAvailable = %@", supported ? @"YES" : @"NO");
  return supported;
}

- (BOOL)isPiPActive {
  BOOL active = self.pipController.isPictureInPictureActive;
  NSLog(@"[PiP] isPiPActive = %@", active ? @"YES" : @"NO");
  return active;
}

- (void)attachToPlayer:(FVPVideoPlayer *)player {
  if (!player) {
    NSLog(@"[PiP] attachToPlayer: player is nil");
    return;
  }
  NSLog(@"[PiP] attachToPlayer: %@", player);
  self.currentPlayer = player;
  [self configureControllerForCurrentPlayer];
}

- (void)detachCurrentPlayer {
  NSLog(@"[PiP] detachCurrentPlayer");
  if (self.isPiPActive) {
    [self stopPiP];
  }
  self.currentPlayer = nil;
  self.pipController = nil;
  self.pipLayer = nil;
}

- (void)configureControllerForCurrentPlayer {
  if (!self.currentPlayer) {
    NSLog(@"[PiP] configureControllerForCurrentPlayer: currentPlayer is nil");
    return;
  }

  if (![AVPictureInPictureController isPictureInPictureSupported]) {
    NSLog(@"[PiP] configure: PiP not supported on this device");
    return;
  }

  AVPlayer *player = self.currentPlayer.player;
  if (!player) {
    NSLog(@"[PiP] configure: player.player is nil");
    return;
  }

  // PiP 専用の AVPlayerLayer（画面には載せない）
  if (self.pipLayer == nil) {
    self.pipLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    self.pipLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    // 見えないようにしておく（PiP のソースとしてのみ使用）
    self.pipLayer.opacity = 0.0;
  } else {
    self.pipLayer.player = player;
  }

  if (self.pipController == nil) {
    AVPictureInPictureControllerContentSource *contentSource =
        [[AVPictureInPictureControllerContentSource alloc] initWithPlayerLayer:self.pipLayer];

    self.pipController =
        [[AVPictureInPictureController alloc] initWithContentSource:contentSource];

    // ★ 自動 PiP 有効化（iOS 14.2+）
    if (@available(iOS 14.2, *)) {
      self.pipController.canStartPictureInPictureAutomaticallyFromInline = YES;
    }

    self.pipController.delegate = self;
    NSLog(@"[PiP] configure: created new PiP controller");
  } else {
    NSLog(@"[PiP] configure: reuse existing PiP controller");
  }
}

- (void)startPiP {
  NSLog(@"[PiP] startPiP called");

  // フォアグラウンドのときだけ手動 PiP 開始を許可
  UIApplicationState state = UIApplication.sharedApplication.applicationState;
  NSLog(@"[PiP] applicationState = %ld", (long)state);
  if (state != UIApplicationStateActive) {
    NSLog(@"[PiP] startPiP blocked: app is not active (state=%ld)", (long)state);
    return;
  }

  if (!self.currentPlayer) {
    NSLog(@"[PiP] startPiP: currentPlayer is nil");
    return;
  }

  if (![AVPictureInPictureController isPictureInPictureSupported]) {
    NSLog(@"[PiP] startPiP: PiP not supported");
    return;
  }

  if (self.pipController == nil) {
    [self configureControllerForCurrentPlayer];
  }

  if (self.pipController == nil) {
    NSLog(@"[PiP] startPiP: pipController is still nil after configure");
    return;
  }

  NSLog(@"[PiP] startPiP: possible=%@ active=%@",
        self.pipController.isPictureInPicturePossible ? @"YES" : @"NO",
        self.pipController.isPictureInPictureActive ? @"YES" : @"NO");

  dispatch_async(dispatch_get_main_queue(), ^{
    if (!self.pipController.isPictureInPictureActive &&
        self.pipController.isPictureInPicturePossible) {
      [self.pipController startPictureInPicture];
      NSLog(@"[PiP] startPiP: startPictureInPicture called");
    } else {
      NSLog(@"[PiP] startPiP: already active or not possible");
    }
  });
}

- (void)stopPiP {
  NSLog(@"[PiP] stopPiP called");
  if (self.pipController.isPictureInPictureActive) {
    [self.pipController stopPictureInPicture];
    NSLog(@"[PiP] stopPiP: stopPictureInPicture called");
  } else {
    NSLog(@"[PiP] stopPiP: not active");
  }
}

#pragma mark - AVPictureInPictureControllerDelegate

- (void)pictureInPictureControllerDidStartPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  NSLog(@"[PiP] didStartPictureInPicture");
}

- (void)pictureInPictureControllerDidStopPictureInPicture:
    (AVPictureInPictureController *)pictureInPictureController {
  NSLog(@"[PiP] didStopPictureInPicture");
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController
    failedToStartPictureInPictureWithError:(NSError *)error {
  NSLog(@"[PiP] failedToStartPictureInPictureWithError: %@", error);
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController
restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:
    (void (^)(BOOL restored))completionHandler {
  NSLog(@"[PiP] restoreUserInterfaceForPictureInPictureStop");
  if (completionHandler) {
    completionHandler(NO);
  }
}

@end
