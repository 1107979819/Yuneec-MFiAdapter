//
//  MediaPlayer.h
//  OBClient
//
//  Created by Alex Lin on 2018/3/3.
//  Copyright © 2018年 yuneec. All rights reserved.
//

#ifndef MediaPlayer_h
#define MediaPlayer_h

#import <YuneecDecoder/YuneecRawVideoFrame.h>
#import <YuneecDecoder/YuneecSampleVideoFrame.h>
#import "YuneecYUVFrame.h"

NS_ASSUME_NONNULL_BEGIN
@class MediaPlayer;

/**
 * Delegate method for MediaPlayer callback
 */
@protocol MediaPlayerDelegate <NSObject>

@optional
/**
 * the MediaPlayer sample video frame display callback method
 *
 * @param mediaPlayer mediaPlayer instance
 * @param sampleFrame output sample video frame
 */
- (void)mediaPlayer:(MediaPlayer *)mediaPlayer displaySampleVideoFrame:(YuneecSampleVideoFrame *)sampleFrame;

/**
 * the MediaPlayer YUV frame display callback method
 *
 * @param mediaPlayer mediaPlayer instance
 * @param yuvFrame output YUV frame
 */
- (void)mediaPlayer:(MediaPlayer *)mediaPlayer displayYuvFrame:(YuneecYUVFrame *)yuvFrame;

/**
 * the MediaPlayer resolution change callback method
 *
 * @param mediaPlayer mediaPlayer instance
 * @param width width of new resolution
 * @param height height of new resolution
 */
- (void)mediaPlayer:(MediaPlayer *)mediaPlayer didChangeResolution:(uint32_t)width Height:(uint32_t)height;

/**
 * the MediaPlayer clear display callback method
 * @param mediaPlayer mediaPlayer instance
 * @param bClear flag to clear
 */
- (void)mediaPlayer:(MediaPlayer *)mediaPlayer clearDisplay:(BOOL)bClear;

/**
 * the MediaPlayer send stream buffer
 * @param mediaPlayer mediaPlayer instance
 * @param sampleBufferRef sample buffer
 * @param isIDR flag of IDR frame
 */
- (void)mediaPlayer:(MediaPlayer *)mediaPlayer sendStreamBuffer:(CMSampleBufferRef)sampleBufferRef IsIDR:(BOOL)isIDR;

/**
 * the MediaPlayer send stream extra data
 * @param mediaPlayer mediaPlayer instance
 * @param extraData extra Data
 */
- (void)mediaPlayer:(MediaPlayer *)mediaPlayer sendStreamExtraData:(NSData * __nullable)extraData;
@end

@interface MediaPlayer: NSObject
+ (instancetype)sharedInstance;
- (void)create:(BOOL)bVTDecoder LowDelay:(BOOL)isLowDelay;
- (void)start;
- (void)stop;
- (void)destroy;
- (void)updateConnectType:(NSUInteger)type;
- (void)clearDisplay;
- (void)getVideoSizeWithWidth:(uint32_t *)width videoHeight:(uint32_t *)height;

- (void)addDelegate:(id<MediaPlayerDelegate>) mediaPlayerDelegate;
- (void)removeDelegate:(id<MediaPlayerDelegate>) mediaPlayerDelegate;
@end

NS_ASSUME_NONNULL_END
#endif /* MediaPlayer_h */
