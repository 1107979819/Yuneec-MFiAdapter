//
//  MFiMediaDownload.m
//  MFiAdapter
//
//  Created by Joe Zhu on 2018/8/20.
//  Copyright © 2018年 Yuneec. All rights reserved.
//

#import "MFiMediaDownload.h"

@implementation MFiMediaDownload

- (id)copyWithZone:(NSZone *)zone{
    MFiMediaDownload * download = [[[self class] allocWithZone:zone] init];

    download.media = _media;
    download.filePath = _filePath;
    download.isThumbnail = _isThumbnail;
    download.isPreviewVideo = _isPreviewVideo;

    return download;
}

@end

