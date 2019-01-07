//
//  MFiOtaAdapter.m
//  MFiAdapter
//
//  Created by Joe Zhu on 2018/9/25.
//  Copyright © 2018年 Yuneec. All rights reserved.
//

#import "MFiOtaAdapter.h"
#import <MFiAdapter/MFiRemoteControllerAdapter.h>
#import "MFiCameraAdapter.h"
#import <YuneecRemoteControllerSDK/YuneecRemoteControllerSDK.h>
#include <CommonCrypto/CommonDigest.h>

@interface MFiOtaAdapter()
    
@end

@implementation MFiOtaAdapter

NSString * const    autopilotFileName = @"autopilot.yuneec";
NSString * const    cameraFileName = @"firmware.bin";
NSString * const    gimbalFileName = @"gimbal.yuneec";
NSString * const    rcFileName = @"update.lzo";

NSString * const    hashFileName = @"hash";
NSString * const    versionFileName = @"version";
NSString * const    cameraVersionFileName = @"version.info";

#pragma mark - init

+ (instancetype)sharedInstance {
    static MFiOtaAdapter *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[MFiOtaAdapter alloc] init];
    });
    return sInstance;
}

- (void)getLatestVersion:(YuneecOtaModuleType) moduleType
                            block:(void (^)(NSString *version))block
{
    NSString *url;
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingString:@"version"];
    __block NSString* versionValue = @"unknown";

    if (fileExistsAtPath(filePath)) {
        deleteFileAtPath(filePath, nil);
    }

    if ([self isCamera:moduleType])
        url = [[self getModuleUrl:moduleType] stringByAppendingString:cameraVersionFileName];
    else
        url = [[self getModuleUrl:moduleType] stringByAppendingString:versionFileName];


    [MFiHttp.sharedInstance downloadSmallFileWithURL:url filePath:filePath block:^(NSError * _Nullable error) {
        if (nil == error) {
            versionValue = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
            versionValue = [versionValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        block(versionValue);
    }];
}

- (void)getLatestHash:(YuneecOtaModuleType) moduleType
                  block:(void (^)(NSString *hash))block
{
    NSString *url;
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingString:@"hash"];
    __block NSString* hashValue = @"unknown";

    if (fileExistsAtPath(filePath)) {
        deleteFileAtPath(filePath, nil);
    }

    url = [[self getModuleUrl:moduleType] stringByAppendingString:hashFileName];

    [MFiHttp.sharedInstance downloadSmallFileWithURL:url filePath:filePath block:^(NSError * _Nullable error) {
        if (nil == error) {
            hashValue = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
            hashValue = [hashValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        block(hashValue);
    }];
}


- (void)downloadOtaPackage:(YuneecOtaModuleType) moduleType filePath:(NSString *)filePath
                        progressBlock:(void (^)(float))progressBlock
                        completionBlock:(void (^)(NSError * _Nullable))completionBlock
{
    NSString * urlString = [self getModuleFileNameUrl:moduleType];

    [MFiHttp.sharedInstance downloadFileWithURL:urlString filePath:filePath progress:progressBlock block:completionBlock];
}


- (void)uploadOtaPackage:(NSString *) filePath
                progressBlock:(void (^)(float)) progressBlock
                completionBlock:(void (^)(NSError *_Nullable)) completionBlock
{
    [MFiCameraAdapter.sharedInstance firmwareUpdate:filePath progressBlock:progressBlock completionBlock:completionBlock];
}

- (void)uploadRemoteControllerOtaPackage:(NSString *) filePath
                   progressBlock:(void (^)(float progress)) progressBlock
                 completionBlock:(void (^)(NSError *_Nullable error)) completionBlock
{
    [MFiRemoteControllerAdapter.sharedInstance firmwareUpdate:filePath progressBlock:progressBlock completionBlock:completionBlock];
}

-(NSString *)sha256OfPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Make sure the file exists
    if( [fileManager fileExistsAtPath:path isDirectory:nil] ) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        unsigned char digest[CC_SHA256_DIGEST_LENGTH];

        CC_SHA256( data.bytes, (CC_LONG)data.length, digest );

        NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];

        for( int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++ ) {
            [output appendFormat:@"%02x", digest[i]];
        }
        return output;
    } else {
        return @"";
    }
}

#pragma mark - private method

- (BOOL)isAutopilot:(YuneecOtaModuleType) moduleType
{
    if (moduleType == YuneecOtaModuleTypeAutopilot)
        return TRUE;
    return FALSE;
}

- (BOOL)isCamera:(YuneecOtaModuleType) moduleType
{
    if (moduleType >= YuneecOtaModuleTypeCameraE50A && moduleType <= YuneecOtaModuleTypeCameraETK)
        return TRUE;
    return FALSE;
}

- (BOOL)isGimbal:(YuneecOtaModuleType) moduleType
{
    if (moduleType >= YuneecOtaModuleTypeGimbalE10T && moduleType <= YuneecOtaModuleTypeGimbalET)
        return TRUE;
    return FALSE;
}

- (BOOL)isRc:(YuneecOtaModuleType) moduleType
{
    if (moduleType == YuneecOtaModuleTypeRcST10C)
        return TRUE;
    return FALSE;
}

- (NSString *)getModuleUrl:(YuneecOtaModuleType) moduleType
{
    NSString *url;

    switch (moduleType) {
        case YuneecOtaModuleTypeAutopilot:
            url = [otaServerUrl stringByAppendingString:@"autopilot/"];
            break;
        case YuneecOtaModuleTypeCameraE50A:
            url = [otaServerUrl stringByAppendingString:@"camera/e50A/"];
            break;
        case YuneecOtaModuleTypeCameraE50E:
            url = [otaServerUrl stringByAppendingString:@"camera/e50E/"];
            break;
        case YuneecOtaModuleTypeCameraE50K:
            url = [otaServerUrl stringByAppendingString:@"camera/e50K/"];
            break;
        case YuneecOtaModuleTypeCameraE90A:
            url = [otaServerUrl stringByAppendingString:@"camera/e90A/"];
            break;
        case YuneecOtaModuleTypeCameraE90E:
            url = [otaServerUrl stringByAppendingString:@"camera/e90E/"];
            break;
        case YuneecOtaModuleTypeCameraE90K:
            url = [otaServerUrl stringByAppendingString:@"camera/e90K/"];
            break;
        case YuneecOtaModuleTypeCameraETA:
            url = [otaServerUrl stringByAppendingString:@"camera/etA/"];
            break;
        case YuneecOtaModuleTypeCameraETE:
            url = [otaServerUrl stringByAppendingString:@"camera/etE/"];
            break;
        case YuneecOtaModuleTypeCameraETK:
            url = [otaServerUrl stringByAppendingString:@"camera/etk/"];
            break;
        case YuneecOtaModuleTypeGimbalE10T:
            url = [otaServerUrl stringByAppendingString:@"gimbal/e10t/"];
            break;
        case YuneecOtaModuleTypeGimbalE50:
            url = [otaServerUrl stringByAppendingString:@"gimbal/e50/"];
            break;
        case YuneecOtaModuleTypeGimbalE90:
            url = [otaServerUrl stringByAppendingString:@"gimbal/e90/"];
            break;
        case YuneecOtaModuleTypeGimbalET:
            url = [otaServerUrl stringByAppendingString:@"gimbal/e90/"];
            break;
        case YuneecOtaModuleTypeRcST10C:
            url = [otaServerUrl stringByAppendingString:@"ST10C/"];
            break;
        default:
            return nil;
    }
    return url;
}

- (NSString *)getModuleFileNameUrl:(YuneecOtaModuleType) moduleType
{
    NSString *url;

    if([self isAutopilot:moduleType])
        url = [[self getModuleUrl:moduleType] stringByAppendingString:autopilotFileName];
    else if ([self isCamera:moduleType])
        url = [[self getModuleUrl:moduleType] stringByAppendingString:cameraFileName];
    else if ([self isGimbal:moduleType])
        url = [[self getModuleUrl:moduleType] stringByAppendingString:gimbalFileName];
    else
        url = [[self getModuleUrl:moduleType] stringByAppendingString:rcFileName];

    return url;
}

- (NSString *)getModuleHashUrl:(YuneecOtaModuleType) moduleType
{
    NSString *url = [[self getModuleUrl:moduleType] stringByAppendingString:hashFileName];

    return url;
}

- (NSString *)getModuleVersionUrl:(YuneecOtaModuleType) moduleType
{
    NSString *url;

    if ([self isCamera:moduleType])
        url = [[self getModuleUrl:moduleType] stringByAppendingString:cameraVersionFileName];
    else
        url = [[self getModuleUrl:moduleType] stringByAppendingString:versionFileName];

    return url;
}


@end

