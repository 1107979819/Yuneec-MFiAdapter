//
//  MFiCameraAdapter.m
//  MFiAdapter
//
//  Created by Joe Zhu on 2018/8/15.
//  Copyright © 2018年 Yuneec. All rights reserved.
//

#import "MFiCameraAdapter.h"

@interface MFiCameraAdapter()

@property (nonatomic, strong) YuneecMediaManager *manager;
@property (nonatomic, strong) YuneecCamera *camera;
@property (nonatomic, strong) dispatch_semaphore_t mediaDownloadLock;
@property (nonatomic, strong) dispatch_queue_t mediaDownloadQueue;
@property (assign, nonatomic) BOOL  cameraTimeInitDoneFlag;
@property (strong, nonatomic) YuneecCameraFileTransfer  *cameraFileTransfer;
@end

@implementation MFiCameraAdapter

#pragma mark - init

+ (instancetype)sharedInstance {
    static MFiCameraAdapter *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[MFiCameraAdapter alloc] init];
    });
    return sInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.manager = [[YuneecMediaManager alloc] initWithCameraType:YuneecCameraTypeE90];
        self.camera = [[YuneecCamera alloc] init];
        self.cameraFileTransfer = [[YuneecCameraFileTransfer alloc] init];
    }
    return self;
}

- (void)requestMediaInfo:(void(^)(NSArray *dateArray, NSError * error))completeCallback
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.manager fetchMediaWithCompletion:^(NSArray<YuneecMedia *> * _Nullable mediaArray, NSError * _Nullable error) {
            if (error == nil) {
                if (mediaArray.count > 0) {
                    NSArray *sortArray = [mediaArray sortedArrayUsingComparator:^NSComparisonResult(YuneecMedia *obj1, YuneecMedia *obj2) {
                        return [obj2.createDate compare:obj1.createDate];
                    }];

                    if (completeCallback != nil) {
                        completeCallback(sortArray, error);
                    }
                }
            } else {
                if (completeCallback != nil) {
                    completeCallback(nil, error);
                }
            }
        }];
    });
}

- (void)stopRequestMediaInfo:(void(^)(NSError *error))completeCallback
{
    [self.manager stopFetchListWithBlock:^(NSError *error) {
        if (completeCallback !=nil) {
            completeCallback(error);
        }
    }];
}

- (void)downloadMedia:(MFiMediaDownload *)download
                             progress:(void (^)(CGFloat progress))progressCallback
                             complete:(void (^)(NSError * _Nullable))completeCallback
{
    __weak typeof(self) weakSelf = self;

    if (download.isThumbnail == YES) {
        [download.media fetchThumbnailWithFilePath:download.filePath block:completeCallback ];
    } else {
        if (download.media.mediaType == YuneecMediaTypeMP4) {
            if (download.isPreviewVideo == YES) {
                [download.media fetchPreviewVideoDataWithFilePath:download.filePath progress:^(float progress, BOOL * _Nullable stop) {
                    *stop = weakSelf.isCancel;
                    if (*stop == YES) {
                        completeCallback(nil);
                    }
                    progressCallback(progress);
                } block:completeCallback ];
            } else {
                [download.media fetchVideoDataWithFilePath:download.filePath progress:^(float progress, BOOL * _Nullable stop) {
                    *stop = weakSelf.isCancel;
                    if (*stop == YES) {
                        completeCallback(nil);
                    }
                    progressCallback(progress);
                } block:completeCallback ];
            }
        } else if (download.media.mediaType == YuneecMediaTypeJPEG) {
            [download.media fetchImageDataWithFilePath:download.filePath progress:^(float progress, BOOL * _Nullable stop) {
                *stop = weakSelf.isCancel;
                if (*stop == YES) {
                    completeCallback(nil);
                }
                progressCallback(progress);
            } block:completeCallback ];
        }
    }
}

- (void)downloadMediasArray:(NSArray<MFiMediaDownload *> *)downloadArray
                                progress:(void (^)(int index,
                                                   NSString *fileName,
                                                   NSString *fileSize,
                                                   CGFloat progress))progressCallback
                                complete:(void (^)(NSError * _Nullable))completeCallback
{
    __weak typeof(self) weakSelf = self;
    __block BOOL toExit = NO;

    if (downloadArray.count == 0) {
        completeCallback(nil);
        return;
    }

    dispatch_async(self.mediaDownloadQueue, ^{
        MFiMediaDownload * download;

        for (int i = 0; i < downloadArray.count; i++) {
            download = [downloadArray objectAtIndex:i];

            [self downloadMedia:download progress:^(CGFloat progress) {
                if (progressCallback != nil) {
                    if (download.isThumbnail == YES) {
                        progressCallback(i + 1, download.media.thumbnailMedia.fileName, download.media.thumbnailMedia.fileSize, progress);
                    } else {
                        if (download.media.mediaType == YuneecMediaTypeMP4) {
                            if (download.isPreviewVideo == YES) {
                                progressCallback(i + 1, download.media.previewMedia.fileName, download.media.previewMedia.fileSize, progress);
                            } else {
                                progressCallback(i + 1, download.media.fileName, download.media.fileSize, progress);
                            }
                        } else if (download.media.mediaType == YuneecMediaTypeJPEG) {
                            progressCallback(i + 1, download.media.fileName, download.media.fileSize, progress);
                        }
                    }
                }
            } complete:^(NSError *error) {
                if ((i == downloadArray.count - 1) || (error != nil) || (weakSelf.isCancel == YES))
                    completeCallback(error);
                if (error != nil) {
                    toExit = YES; //exit loop after error
                }
                    dispatch_semaphore_signal(self.mediaDownloadLock);
                }];

            dispatch_semaphore_wait(self.mediaDownloadLock, DISPATCH_TIME_FOREVER);
            if (weakSelf.isCancel == YES) {
                weakSelf.isCancel = NO;
                return;
            }
            if (toExit == YES) {
                return;
            }
        }
    });
}

- (void)deleteMediasArray:(NSArray<YuneecMedia *> *)mediaArray complete:(void (^)(NSError * _Nullable))completeCallback
{
    [self.manager deleteMedia:mediaArray withCompletion:completeCallback];
}

- (void)formatCameraStorage:(void (^)(NSError * _Nullable))completionCallback
{
    [self.camera formatCameraStorage:^(NSError * _Nullable error) {
        if(completionCallback != nil) {
            completionCallback(error);
        }
    }];
}

- (void)setCameraSystemTime
{
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        weakSelf.cameraTimeInitDoneFlag = NO;
        uint32_t retryCnt = 0;
        while(!weakSelf.cameraTimeInitDoneFlag && (retryCnt < 3)) {
            NSDate *date = [NSDate date];
            NSTimeInterval time = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:date];
            NSDate *dateNow = [[NSDate date] dateByAddingTimeInterval:time];
            uint64_t timeInUs = [dateNow timeIntervalSince1970]*1000000;
            NSLog(@"Init camera sytem time.....");
            [self.camera setCameraSystemTime:timeInUs block:^(NSError * _Nullable error) {
                if (error != nil) {
                    weakSelf.cameraTimeInitDoneFlag = NO;
                    NSLog(@"Set system time failed:%@", error.localizedDescription);
                }
                else {
                    weakSelf.cameraTimeInitDoneFlag = YES;
                    NSLog(@"Succeed to init camera system time!");
                }
            }];
            retryCnt++;
            [NSThread sleepForTimeInterval:5.0f];
            if(weakSelf.cameraTimeInitDoneFlag) {
                break;
            }
        }
    });
}

- (void)firmwareUpdate:(NSString *) filePath
         progressBlock:(void (^)(float progress)) progressBlock
       completionBlock:(void (^)(NSError *_Nullable error)) completionBlock
{
    [self.cameraFileTransfer transferFileToCamera:filePath progressBlock:progressBlock completionBlock:completionBlock];
}

- (void)getFirmwareVersion:(void(^)(NSString * _Nullable firmwareVersion)) completionBlock
{
    [self.camera getCameraVersionInfo:^(NSError * _Nullable error, YuneecCameraType cameraType, NSString * _Nullable cameraName, NSString * _Nullable version, NSString * _Nullable branch) {
        if (error != nil) {
            completionBlock(@"Unknown");
            NSLog(@"getCameraVersionInfo failed%@", error.localizedDescription);
        } else {
            NSString *firmwareVersion = [NSString stringWithFormat:@"v%@_%@_%@", version,branch,cameraName];
            completionBlock(firmwareVersion);
        }
    }];
}

- (void)getGimbalFirmwareVersion:(void(^)(NSString * _Nullable firmwareVersion)) completionBlock
{
    [self.camera getGimbalVersionInfo:^(NSError * _Nullable error, NSString * _Nullable version) {
        if (error != nil) {
            completionBlock(@"Unknown");
            NSLog(@"getGimbalVersionInfo failed%@", error.localizedDescription);
        } else {
            NSString *firmwareVersion = [NSString stringWithFormat:@"v%@", version];
            completionBlock(firmwareVersion);
        }
    }];
}
#pragma mark - get & set

- (dispatch_semaphore_t)mediaDownloadLock
{
    if (!_mediaDownloadLock) {
        _mediaDownloadLock = dispatch_semaphore_create(0);
    }
    return _mediaDownloadLock;
}

- (dispatch_queue_t)mediaDownloadQueue
{
    if (!_mediaDownloadQueue) {
        _mediaDownloadQueue = dispatch_queue_create("com.yuneec.mediaDownload", DISPATCH_QUEUE_SERIAL);
    }
    return _mediaDownloadQueue;
}

@end
