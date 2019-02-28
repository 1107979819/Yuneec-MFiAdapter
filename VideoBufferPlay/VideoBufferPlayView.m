//
//  VideoBufferPlayView.m
//  VideoBufferPlay
//
//  Created by alexlin on 18/1/15.
//  Copyright © 2018年 yuneec. All rights reserved.
//

#import "VideoBufferPlayView.h"


#define UIColorFromHexRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 alpha:1.0]

@interface VideoBufferPlayView()
@property(nonatomic,assign) CVPixelBufferRef        lastPixelBuffer;
@property(nonatomic) BOOL                           bStop;
@property (strong, nonatomic) NSLock                *playLock;

@end
@implementation VideoBufferPlayView
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.displayFrame = frame;
        [self createLayer];
    }
    return self;
}

- (void)createLayer
{
    [self.playLock lock];
    _bStop = YES;
    if (!self.bufferLayer) {
        self.bufferLayer = [[AVSampleBufferDisplayLayer alloc] init];
        self.bufferLayer.frame = self.displayFrame;
        self.bufferLayer.bounds = self.displayFrame;
        self.bufferLayer.position = CGPointMake(CGRectGetMidX(self.displayFrame), CGRectGetMidY(self.displayFrame));
        UIColor *bgColor = UIColorFromHexRGB(0x222222);
        self.bufferLayer.backgroundColor = bgColor.CGColor;

        /*!
         @constant		AVLayerVideoGravityResizeAspect  根据图像像素比例 绘制图像 图像会填充不满图层size
         @abstract		Preserve aspect ratio; fit within layer bounds.

         @constant		AVLayerVideoGravityResizeAspectFill  根据像素比例 填充图层 画面会超出图层size
         @abstract		Preserve aspect ratio; fill layer bounds.

         @constant		AVLayerVideoGravityResize   拉伸 用这个自适应不同size图层最好
         @abstract		Stretch to fill layer bounds.
         */
        self.bufferLayer.videoGravity = AVLayerVideoGravityResize;
        self.bufferLayer.opaque = YES;
        [self.layer addSublayer:self.bufferLayer];
    }
    else {
        [self privateUpdateLayer:self.displayFrame];
        [self.bufferLayer flush];
    }
    _bStop = NO;
    [self.playLock unlock];
}

- (void)updateLayer:(CGRect)frame {
    [self.playLock lock];
    [self privateUpdateLayer:frame];
    [self.playLock unlock];
}

- (void)privateUpdateLayer:(CGRect)frame {
    self.displayFrame = frame;
    if(self.bufferLayer != nil) {
        [self.bufferLayer flushAndRemoveImage];
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.bufferLayer.frame = self.displayFrame;
        self.bufferLayer.position = CGPointMake(CGRectGetMidX(self.displayFrame), CGRectGetMidY(self.displayFrame));
        [CATransaction commit];
    }
}

#pragma mark - 显示缓存图片
- (void)show_backGroundImage
{
    if (self.lastPixelBuffer) {
        self.image = [self get_image_from_tmp];
        CFRelease(self.lastPixelBuffer);
        self.lastPixelBuffer = nil;
    }
}

- (UIImage*)get_image_from_tmp
{
    UIImage * ima = nil;
    CIImage * ciimage = [CIImage imageWithCVPixelBuffer:self.lastPixelBuffer];
    ima = [UIImage imageWithCGImage:(__bridge CGImageRef _Nonnull)(ciimage)];
    UIGraphicsBeginImageContext(self.bounds.size);
    [ima drawInRect:self.bounds];
    ima = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ima;
}

#pragma mark - play
// 每来一帧数据进行缓存, 从后台模式返回后, 重启layer
- (void)play:(CMSampleBufferRef)buffer
{
    [self.playLock lock];
    if ((buffer != nil) && (!_bStop) && (_bufferLayer != nil)) {
        [_bufferLayer enqueueSampleBuffer:buffer];
        if (_bufferLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            NSLog(@"avqueue sample fail, error=%ld", _bufferLayer.error.code);
            if(-11847 == _bufferLayer.error.code) {
                //flush to handle error# -11847
                [_bufferLayer flush];
            }
            else {
                [self rebuildSampleBufferDisplayLayer];
            }
        }
        else if(_bufferLayer.status == AVQueuedSampleBufferRenderingStatusUnknown) {
            NSLog(@"Unknown status");
        }
    }
    [self.playLock unlock];
}

- (void)clear {
    [self.playLock lock];
    if(_bufferLayer != nil) {
        [_bufferLayer flushAndRemoveImage];
    }
    [self.playLock unlock];
}

- (void)flush {
    [self.playLock lock];
    if(_bufferLayer != nil) {
        [_bufferLayer flush];
    }
    [self.playLock unlock];
}

- (void)blank:(BOOL)isBlank {
    if(_bufferLayer != nil) {
        [CATransaction setDisableActions:YES];
        [_bufferLayer setHidden:isBlank];
    }
}

#pragma mark - 重启渲染layer
- (void)rebuildSampleBufferDisplayLayer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeLayer];
        [self createLayer];
    });
}

- (void)removeLayer
{
    [self.playLock lock];
    _bStop = YES;
    [_bufferLayer flush];
    if (self.bufferLayer) {
        [self.bufferLayer stopRequestingMediaData];
        [self.bufferLayer removeFromSuperlayer];
        self.bufferLayer = nil;
    }
    [self.playLock unlock];
}

- (void)dealloc
{
    _bStop = YES;
    if (self.lastPixelBuffer) {
        CFRelease(self.lastPixelBuffer);
        self.lastPixelBuffer = nil;
    }
    _playLock = nil;
}

#pragma mark - get & set

- (NSLock *)playLock {
    if (_playLock == nil) {
        _playLock = [[NSLock alloc] init];
    }
    return _playLock;
}
@end
