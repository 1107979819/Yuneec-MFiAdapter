//
//  YuneecYUVFrame.h
//  YuneecDecoder
//
//  Created by alexlin on 18/1/9.
//  Copyright © 2018年 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>

// Format of YUVFrame: YYYYYYYYUUVV
@interface YuneecYUVFrame : NSObject

/**
 *  Frame Pixel Format Type
 */
typedef NS_ENUM(NSUInteger, FramePixelFmtType)
{
    FramePixelFmtTypeI420 = 0,
    FramePixelFmtTypeNV12,
    FramePixelFmtTypeNV21,
};

@property (nonatomic, readonly) uint32_t                width;
@property (nonatomic, readonly) uint32_t                height;
@property (nonatomic, readonly) FramePixelFmtType       fmtType;
@property (nonatomic, readonly) uint32_t                ySize;
@property (nonatomic, readonly) uint32_t                uSize;
@property (nonatomic, readonly) uint32_t                vSize;
@property (nonatomic, readonly) uint8_t*                yBuffer;
@property (nonatomic, readonly) uint8_t*                uBuffer;
@property (nonatomic, readonly) uint8_t*                vBuffer;
@property (nonatomic, readonly) BOOL                    isPipVideo;

- (instancetype)initWithWidth:(uint32_t) width
                       height:(uint32_t) height
                 pixelFmtType:(FramePixelFmtType) fmtType
                        ysize:(uint32_t) ySize
                        usize:(uint32_t) uSize
                        vsize:(uint32_t) vSize
                      yBuffer:(uint8_t *) yBuffer
                      uBuffer:(uint8_t *) uBuffer
                      vBuffer:(uint8_t *) vBuffer
                   IsPipVideo:(BOOL) isPipVideo;

@end
