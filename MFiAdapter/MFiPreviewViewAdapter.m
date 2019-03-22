//
//  YuneecPreviewViewController.m
//  YuneecPreviewDemo
//
//  Created by tbago on 07/02/2018.
//  Copyright © 2018 yuneec. All rights reserved.
//

#import "MFiPreviewViewAdapter.h"
#import "MFiConnectionStateAdapter.h"
#import <YuneecDataTransferManager/YuneecDataTransferManager.h>
#import <YuneecPreviewView/YuneecPreviewView.h>
#import <YuneecDataTransferManager/YuneecDataTransferConnectionState.h>
#import <BaseFramework/DeviceUtility.h>
#import <YuneecMediaPlayer/YuneecMediaPlayer.h>
#import <VideoBufferPlayView.h>


@interface MFiPreviewViewAdapter () <MediaPlayerDelegate>

@property (weak, nonatomic) YuneecPreviewView      *previewView;

/* display rect is the size/pos of display content with ratio */
@property (nonatomic, assign)                       CGRect previewDisplayRect;

///< Video Buffer play view
@property(nonatomic,strong)VideoBufferPlayView                      *mainVideoView;
@property(nonatomic,strong)VideoBufferPlayView                      *pipVideoView;
@property (nonatomic, assign) BOOL                                  isCompressData;;
@end

@implementation MFiPreviewViewAdapter

+ (instancetype)sharedInstance {
    static MFiPreviewViewAdapter *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[MFiPreviewViewAdapter alloc] init];
    });
    return sInstance;
}

-(void) startVideo:(YuneecPreviewView *)previewView
completionCallback:(void (^)(NSString * _Nullable))completionCallback {
    WS(weakSelf);
    self.previewView = previewView;
    if ((self.previewDisplayRect.size.width == 0) || (self.previewDisplayRect.size.height == 0))
        self.previewDisplayRect = previewView.frame; //default
    BOOL isConnected = [[MFiConnectionStateAdapter sharedInstance] connected];
    if (isConnected) {
        //NSDictionary *connectionInfo = [[MFiConnectionStateAdapter sharedInstance] getConnectionStatus];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [weakSelf stopDisplayVideo];
            [[MediaPlayer sharedInstance] stop];
            [[MediaPlayer sharedInstance] destroy];
            weakSelf.isCompressData = YES;
            [[MediaPlayer sharedInstance] updateConnectType:YuneecDataTransferConnectionTypeMFi];
            [[MediaPlayer sharedInstance] create:YES LowDelay:NO];
            [[MediaPlayer sharedInstance] start];
            [weakSelf startDisplayVideo];
        });
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(completionCallback != nil) {
                completionCallback(@"No Connection");
            }
        });
        [weakSelf stopDisplayVideo];
        [self.previewView clearFrame];
    }
}

- (void)stopVideo:(void (^)(NSString * _Nullable))completionCallback {
    WS(weakSelf);
    BOOL isConnected = [[MFiConnectionStateAdapter sharedInstance] connected];
        if (isConnected) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                if(completionCallback != nil) {
                    completionCallback(@"Stop Video Successful");
                }
                [weakSelf stopDisplayVideo];
            });
        }
    else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [weakSelf stopDisplayVideo];
            [self.previewView clearFrame];
        });
    }
}

- (void) updateDisplayRect:(CGRect) displayRect {
    self.previewDisplayRect = displayRect;
    if(_mainVideoView != nil) {
        [_mainVideoView updateLayer:self.previewDisplayRect];
    }
}
#pragma mark - MediaPlayerDelegate

- (void)mediaPlayer:(MediaPlayer *)mediaPlayer clearDisplay:(BOOL)bClear {
    if((bClear) && (_mainVideoView != nil)) {
        [_mainVideoView clear];
    }
}

- (void)mediaPlayer:(MediaPlayer *)mediaPlayer displaySampleVideoFrame:(YuneecSampleVideoFrame *)sampleFrame {
    const BOOL isPipVideo = sampleFrame.isPipVideo;
    if(!isPipVideo) {
        if(_isCompressData != sampleFrame.bIsCompressedData) {
            if(_mainVideoView != nil) {
                [_mainVideoView clear];
            }
            _isCompressData = sampleFrame.bIsCompressedData;
         }

        if(_mainVideoView != nil) {
            [_mainVideoView play:sampleFrame.sampleBuffer];
        }
    }
    else {
        if(_pipVideoView != nil) {
            [_pipVideoView play:sampleFrame.sampleBuffer];
        }
    }
}

- (void)mediaPlayer:(MediaPlayer *)mediaPlayer displayYuvFrame:(YuneecYUVFrame *)yuvFrame {

}

- (void)mediaPlayer:(MediaPlayer *)mediaPlayer didChangeResolution:(uint32_t)width Height:(uint32_t)height {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.mainVideoView != nil) {
            [_mainVideoView updateLayer:self.previewDisplayRect];
        }
    });
}

- (void)mediaPlayer:(MediaPlayer *)mediaPlayer sendStreamBuffer:(CMSampleBufferRef)sampleBufferRef IsIDR:(BOOL)isIDR {

}


#pragma mark - get & set

- (void)initDisplayVideoView {
    if(_mainVideoView == nil) {
        // create buffer play view
        _mainVideoView = [[VideoBufferPlayView alloc]initWithFrame:self.previewView.frame];
        [_mainVideoView createLayer];
    }
    if(![self.mainVideoView isDescendantOfView:self.previewView]) {
        [self.previewView insertSubview:self.mainVideoView atIndex:0];
    }
}

- (void)removeDisplayVideoView {
    if(_mainVideoView != nil) {
        [_mainVideoView removeLayer];
        [_mainVideoView removeFromSuperview];
        _mainVideoView = nil;
    }
}

- (void)startDisplayVideo {
    [self controlDisplay:YES HWDisplay:YES];
    [[MediaPlayer sharedInstance] addDelegate:self];
}

- (void)stopDisplayVideo {
    [[MediaPlayer sharedInstance] removeDelegate:self];
    [self controlDisplay:NO HWDisplay:YES];
}

- (void)controlDisplay:(BOOL)bEnable HWDisplay:(BOOL)bHardware {
    if(bEnable && bHardware){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self initDisplayVideoView];
        });
    }
    else if(!bEnable && !bHardware) {
        [self.previewView clearFrame];
    }
    else if(_mainVideoView != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeDisplayVideoView];
        });
    }
}

@end

