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
#import <YuneecDecoder/YuneecDecoder.h>
#import <YuneecPreviewView/YuneecPreviewView.h>
#import <YuneecDataTransferManager/YuneecDataTransferConnectionState.h>
#import <BaseFramework/DeviceUtility.h>

@interface MFiPreviewViewAdapter () <YuneecCameraStreamDataTransferDelegate,
YuneecDecoderDelegate>

@property (weak, nonatomic) YuneecPreviewView      *previewView;

@property (strong, nonatomic) YuneecDecoder                 *decoder;
@property (weak, nonatomic) YuneecCameraStreamDataTransfer  *cameraStreamTransfer;
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
    self.previewView = previewView;
    BOOL isConnected = [[MFiConnectionStateAdapter sharedInstance] connected];
    if (isConnected) {
        //NSDictionary *connectionInfo = [[MFiConnectionStateAdapter sharedInstance] getConnectionStatus];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            BOOL ret = [self.decoder openCodec];
            if (!ret) {
                if(completionCallback != nil) {
                    completionCallback(@"Open Yuneec Decoder failed");
                    return;
                }
            }
            [self.cameraStreamTransfer openCameraSteamDataTransfer];
        });
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(completionCallback != nil) {
                completionCallback(@"No Connection");
            }
        });
        [self.decoder closeCodec];
        [self.previewView clearFrame];
    }
}

- (void)stopVideo:(void (^)(NSString * _Nullable))completionCallback {
    BOOL isConnected = [[MFiConnectionStateAdapter sharedInstance] connected];
        if (isConnected) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                if(completionCallback != nil) {
                    completionCallback(@"Stop Video Successful");
                }
                [self.decoder closeCodec];
                [self.cameraStreamTransfer closeCameraStreamDataTransfer];
            });
        }
    else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self.decoder closeCodec];
            [self.previewView clearFrame];
        });
    }
}

#pragma mark - YuneecCameraStreamDataTransferDelegate

- (void)cameraStreamDataTransfer:(YuneecCameraStreamDataTransfer *) cameraStreamDataTransfer
              didReceiveH264Data:(NSData *) h264Data
                        keyFrame:(BOOL) keyFrame
              decompassTimeStamp:(int64_t) decompassTimeStamp
                presentTimeStamp:(int64_t) presentTimeStamp
                       extraData:(NSData * __nullable) extraData
{
    [self.decoder decodeVideoFrame:h264Data
                decompassTimeStamp:decompassTimeStamp
                  presentTimeStamp:presentTimeStamp];
}

#pragma mark - YuneecDecoderDelegate

static uint64_t preDisplayTime = 0;
static const uint64_t displayInternal = 20;

- (void)decoder:(YuneecDecoder *) decoder didDecoderVideoFrame:(YuneecRawVideoFrame *) rawVideoFrame {
    uint64_t currentTime = [[NSDate date] timeIntervalSince1970]*1000;
    if (currentTime - preDisplayTime > displayInternal) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self renderVideoFrame:rawVideoFrame];
            preDisplayTime = currentTime;
        });
    }
}

- (void)renderVideoFrame:(YuneecRawVideoFrame *) rawVideoFrame {
    const uint32_t yFrameSize = rawVideoFrame.width * rawVideoFrame.height;
    uint32_t bufferSize = yFrameSize * 3 / 2 + 1;
    int8_t *buffer = (int8_t *)malloc(bufferSize);
    uint32_t bufferIndex = 0;

    uint32_t lineSize0 = (uint32_t)[rawVideoFrame.lineSizeArray[0] integerValue];
    uint8_t *yBuffer = (uint8_t *)[rawVideoFrame.frameDataArray[0] bytes];

    uint32_t lineSize1 = (uint32_t)[rawVideoFrame.lineSizeArray[1] integerValue];
    uint8_t *uBuffer = (uint8_t *)[rawVideoFrame.frameDataArray[1] bytes];

    uint32_t lineSize2 = (uint32_t)[rawVideoFrame.lineSizeArray[2] integerValue];
    uint8_t *vBuffer = (uint8_t *)[rawVideoFrame.frameDataArray[2] bytes];

    ///< copy y data
    if(lineSize0 == rawVideoFrame.width) {
        bufferIndex = yFrameSize;
        memcpy(buffer, yBuffer, bufferIndex);
    }
    else {
        for (uint32_t i = 0; i < rawVideoFrame.height; i++) {
            memcpy(buffer + bufferIndex, yBuffer + i * lineSize0, rawVideoFrame.width);
            bufferIndex += rawVideoFrame.width;
        }
    }

    ///< copy u data
    if(lineSize1 == rawVideoFrame.width/2) {
        memcpy(buffer + bufferIndex, uBuffer, yFrameSize/4);
        bufferIndex += yFrameSize/4;
    }
    else {
        for (uint32_t i = 0; i < rawVideoFrame.height/2; i++) {
            memcpy(buffer + bufferIndex, uBuffer + i * lineSize1, rawVideoFrame.width/2);
            bufferIndex += rawVideoFrame.width/2;
        }
    }

    ///< copy v data
    if(lineSize2 == rawVideoFrame.width/2) {
        memcpy(buffer + bufferIndex, vBuffer, yFrameSize/4);
        bufferIndex += yFrameSize/4;
    }
    else {
        for (uint32_t i = 0; i < rawVideoFrame.height/2; i++) {
            memcpy(buffer + bufferIndex, vBuffer + i * lineSize2, rawVideoFrame.width/2);
            bufferIndex += rawVideoFrame.width/2;
        }
    }

    [self.previewView displayYUV420pData:buffer
                                   width:rawVideoFrame.width
                                  height:rawVideoFrame.height
                                pixelFmt:YuneecPreviewPixelFmtTypeI420];
    free(buffer);
}

#pragma mark - get & set

- (YuneecCameraStreamDataTransfer *)cameraStreamTransfer {
    if (_cameraStreamTransfer == nil) {
        _cameraStreamTransfer = [YuneecDataTransferManager sharedInstance].streamDataTransfer;
        _cameraStreamTransfer.cameraStreamDelegate = self;
        _cameraStreamTransfer.enableLowDelay = YES;
    }
    return _cameraStreamTransfer;
}

- (YuneecDecoder *)decoder {
    if (_decoder == nil) {
        BOOL enableLowDelay = YES;
        _decoder = createYuneecDecoder(self, NO, enableLowDelay);
    }
    return _decoder;
}
@end

