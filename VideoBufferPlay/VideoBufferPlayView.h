//
//  VideoBufferPlayView.m
//  VideoBufferPlay
//
//  Created by alexlin on 18/1/15.
//  Copyright © 2018年 yuneec. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface VideoBufferPlayView : UIImageView
@property(nonatomic,assign) CGRect displayFrame;
@property(nonatomic,strong) AVSampleBufferDisplayLayer * bufferLayer;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)play:(CMSampleBufferRef)buffer;
- (void)clear;
- (void)flush;
- (void)createLayer;
- (void)removeLayer;
- (void)updateLayer:(CGRect)frame;
- (void)blank:(BOOL)isBlank;
@end
