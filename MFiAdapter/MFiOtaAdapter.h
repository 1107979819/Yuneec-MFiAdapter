//
//  MFiOtaAdapter.h
//  MFiAdapter
//
//  Created by Joe Zhu on 2018/9/25.
//  Copyright © 2018年 Yuneec. All rights reserved.
//

#import <YuneecCameraSDK/YuneecCameraSDK.h>
#import "MFiHttp.h"

/// This interface provides methods to perform OTA updates of the firmwares. The firmwares supported by this interface are Remote Controller, Camera, Auto Pilot and Gimbal.
@interface MFiOtaAdapter : NSObject;

/**
 Yuneec OTA module type
 */
typedef NS_ENUM (NSUInteger, YuneecOtaModuleType) {
    ///Autopilot
    YuneecOtaModuleTypeAutopilot,
    ///Camera E50A
    YuneecOtaModuleTypeCameraE50A,
    ///Camera E50E
    YuneecOtaModuleTypeCameraE50E,
    ///Camera E50K
    YuneecOtaModuleTypeCameraE50K,
    ///Camera E90A
    YuneecOtaModuleTypeCameraE90A,
    ///Camera E90E
    YuneecOtaModuleTypeCameraE90E,
    ///Camera E90K
    YuneecOtaModuleTypeCameraE90K,
    ///Camera ETA
    YuneecOtaModuleTypeCameraETA,
    ///Camera ETE
    YuneecOtaModuleTypeCameraETE,
    ///Camera ETK
    YuneecOtaModuleTypeCameraETK,
    ///Camera E10T
    YuneecOtaModuleTypeGimbalE10T,
    ///Gimbal E50
    YuneecOtaModuleTypeGimbalE50,
    ///Gimbal E90
    YuneecOtaModuleTypeGimbalE90,
    ///Gimbal ET
    YuneecOtaModuleTypeGimbalET,
    ///ST10C
    YuneecOtaModuleTypeRcST10C,
};

/**
 * Singleton object
 *
 * @return MFiOtaAdapter singleton instance
 */
+ (instancetype)sharedInstance;

/**
 * Get latest firmware version
 *
 * @param moduleType YuneecOtaModuleType of the firmware.
 * @param block Completion block.
 */
- (void)getLatestVersion:(YuneecOtaModuleType) moduleType
                block:(void (^)(NSString *version))block;

/**
 * Get latest hash
 *
 * @param moduleType YuneecOtaModuleType of the firmware.
 * @param block Completion block.
 */
- (void)getLatestHash:(YuneecOtaModuleType) moduleType
                block:(void (^)(NSString *hash))block;

/**
 * Download the OTA file
 *
 * @param moduleType YuneecOtaModuleType of the firmware.
 * @param filePath file path
 * @param progressBlock OTA file download progress block
 * @param completionBlock Completion block.
 */
- (void)downloadOtaPackage:(YuneecOtaModuleType) moduleType filePath:(NSString *)filePath
                progressBlock:(void (^)(float))progressBlock
                completionBlock:(void (^)(NSError * _Nullable))completionBlock;

/**
 * Upload the OTA file
 *
 * @param filePath file path
 * @param progressBlock OTA file upload progress block
 * @param completionBlock Completion block.
 */
- (void)uploadOtaPackage:(NSString *) filePath
                progressBlock:(void (^)(float)) progressBlock
                completionBlock:(void (^)(NSError *_Nullable)) completionBlock;

/**
 * Upload Remote Controller OTA file
 *
 * @param filePath file path
 * @param progressBlock OTA file upload progress block
 * @param completionBlock Completion block.
 */
- (void)uploadRemoteControllerOtaPackage:(NSString *) filePath
                progressBlock:(void (^)(float progress)) progressBlock
                completionBlock:(void (^)(NSError *_Nullable error)) completionBlock;

-(NSString *)sha256OfPath:(NSString *)path;
@end
