//
//  MFiHttp.m
//  MFiAdapter
//
//  Created by Joe Zhu on 2018/9/26.
//  Copyright © 2018年 Yuneec. All rights reserved.
//
#import "MFiHttp.h"
#import <AFNetworking/AFNetworking.h>


@interface MFiHttp()

@property(nonatomic, strong) AFURLSessionManager *manager;
@end


@implementation MFiHttp


#pragma mark - init

+ (instancetype)sharedInstance {
    static MFiHttp *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[MFiHttp alloc] init];
    });
    return sInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = 15;
        configuration.requestCachePolicy = 0;
        self.manager = [[AFURLSessionManager alloc]initWithSessionConfiguration:configuration];
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
        securityPolicy.allowInvalidCertificates = NO;
        self.manager.securityPolicy = securityPolicy;
    }
    return self;
}


//small file
- (void)downloadSmallFileWithURL:(NSString *)urlString filePath:(NSString *)filePath block:(void (^)(NSError * _Nullable))block {

    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    NSURLSessionDownloadTask *downloadTask = [self.manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
        block(error);
    }];
    [downloadTask resume];
}

//big file
- (void)downloadFileWithURL:(NSString *)urlString filePath:(NSString *)filePath progress:(void (^)(float))progress block:(void (^)(NSError * _Nullable))block {

    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    NSURLSessionDownloadTask *downloadTask = [self.manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        progress(downloadProgress.fractionCompleted);
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
        block(error);
    }];
    [downloadTask resume];
}


- (void)uploadFileWithURL:(NSString *)filePath url:(NSString *)urlString progress:(void (^)(float))progress block:(void (^)(NSError * _Nullable))block {

    NSFileManager *fileManager = [[NSFileManager alloc] init];
    unsigned long long fileSize = 0;

    if ([fileManager fileExistsAtPath:filePath]) {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:filePath error:nil];
        fileSize = [[fileDic objectForKey:NSFileSize] longLongValue];
    }

    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:urlString parameters:nil error:nil];
    [request setValue:[[NSNumber numberWithUnsignedLongLong:fileSize] stringValue] forHTTPHeaderField:@"File-Size"];

    NSURL *src = [NSURL URLWithString:filePath];

    NSURLSessionUploadTask *uploadTask = [self.manager uploadTaskWithRequest:request fromFile:src progress:^(NSProgress * _Nonnull uploadProgress) {
        progress(uploadProgress.fractionCompleted);
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        block(error);
    }];
    [uploadTask resume];
}


@end
