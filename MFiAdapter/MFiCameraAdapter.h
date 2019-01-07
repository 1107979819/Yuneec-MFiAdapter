//
//  MFiCameraAdapter.h
//  MFiAdapter
//
//  Created by Joe Zhu on 2018/8/15.
//  Copyright © 2018年 Yuneec. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <YuneecCameraSDK/YuneecCameraSDK.h>
#import "MFiMediaDownload.h"

/// This interface provides methods to get information/data from the camera.
@interface MFiCameraAdapter : NSObject;

/**
 * This variable is set to cancel the download of a media.
 * Set this variable to true to cancel the download
 */
@property (nonatomic, assign) BOOL isCancel;

/**
 * Singleton object
 *
 * @return MFiCameraAdapter singleton instance
 */
+ (instancetype)sharedInstance;

/**
 *  Fetch the media list from the remote album.
 *
 *  @param completeCallback Completion block. On success, objects in mediaArray will have the list of media. When this call fails, the error will have the failure information.
 */
- (void)requestMediaInfo:(void(^)(NSArray *mediaArray, NSError * error))completeCallback;

/**
 *  Stop fetching media list.
 *
 *  @param completeCallback Completion block.
 */
- (void)stopRequestMediaInfo:(void(^)(NSError *error))completeCallback;

/**
 *  Download Media from the remote album.
 *
 *  @param progressCallback Progress block.
 *  @param completeCallback Completion block.
 */
- (void)downloadMediasArray:(NSArray<MFiMediaDownload *> *)downloadArray
                        progress:(void (^)(int index,
                                      NSString *fileName,
                                      NSString *fileSize,
                                      CGFloat progress))progressCallback
                        complete:(void (^)(NSError * _Nullable))completeCallback;

/**
 *  Delete the media from the remote album.
 *
 *  @param mediaArray Media need to be deleted.
 *  @param completeCallback Completion block. When failed the error will show failed reason.
 */
- (void)deleteMediasArray:(NSArray<YuneecMedia *> *)mediaArray
                        complete:(void (^)(NSError * _Nullable))completeCallback;
/**
 * Format camera internal storage
 *
 * @param completionCallback A block object to be executed when the command returns.
 */
- (void)formatCameraStorage:(void(^)(NSError * _Nullable error)) completionCallback;

/**
 * Set camera system time to current local time
 *
 */
- (void)setCameraSystemTime;

/**
 * Upgrade firmware
 *
 * @param filePath file path
 * @param progressBlock Update progress block
 * @param completionBlock Completion block
 */
- (void)firmwareUpdate:(NSString *) filePath
            progressBlock:(void (^)(float progress)) progressBlock
            completionBlock:(void (^)(NSError *_Nullable error)) completionBlock;

/**
 *  Get Camera version info
 *
 *  @param completionBlock Completion block. On success, this call will return the current camera firmware version.
 */
- (void)getFirmwareVersion:(void(^)(NSString * _Nullable firmwareVersion)) completionBlock;

/**
 *  Get Gimbal version info
 *
 *  @param completionBlock Completion block. On success, this call will return the current gimbal firmware version.
 */
- (void)getGimbalFirmwareVersion:(void(^)(NSString * _Nullable firmwareVersion)) completionBlock;
@end
