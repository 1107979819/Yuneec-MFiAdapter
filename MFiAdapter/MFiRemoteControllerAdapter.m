//
//  MFiRemoteControllerAdapter.m
//  MFiAdapter
//
//  Created by Sushma Sathyanarayana on 5/2/18.
//  Copyright © 2018 Yuneec. All rights reserved.
//

#import "MFiRemoteControllerAdapter.h"
#import "MFiConnectionStateAdapter.h"

@interface MFiRemoteControllerAdapter() <YuneecRemoteControllerDelegate, YuneecRemoteControllerKeyDelegate>
@property (strong, nonatomic) YuneecRemoteController    *remoteController;
@property (strong, nonatomic) YuneecRemoteControllerKey    *remoteControllerKey;
@property (nonatomic, strong) YuneecRemoteControllerFirmwareTransfer *remoteControlFileTransfer;
@end

@implementation MFiRemoteControllerAdapter

NSString * const kRemoteControllerKeyNotification = @"RemoteControllerKeyNotification";
int currentEventId = 0;
int currentEventValue = 0;


#pragma mark - init

+ (instancetype)sharedInstance {
    static MFiRemoteControllerAdapter *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[MFiRemoteControllerAdapter alloc] init];
    });
    return sInstance;
}

- (instancetype)init {
    self = [super init];
    return self;
}

- (YuneecRemoteController *)remoteController {
    if (_remoteController == nil) {
        _remoteController = [[YuneecRemoteController alloc] init];
    }
    return _remoteController;
}

- (YuneecRemoteControllerKey *)remoteControllerKey {
    if (_remoteControllerKey == nil) {
        _remoteControllerKey = [YuneecRemoteControllerKey sharedInstance];
    }
    return _remoteControllerKey;
}

- (YuneecRemoteControllerFirmwareTransfer *)remoteControlFileTransfer {
    if (_remoteControlFileTransfer == nil) {
        _remoteControlFileTransfer = [[YuneecRemoteControllerFirmwareTransfer alloc] initWithRemoteController:[MFiRemoteControllerAdapter sharedInstance].remoteController];
    }
    return _remoteControlFileTransfer;
}

#pragma mark - public method

- (void) startMonitorRCEvent {
    [self.remoteController setDelegate:self];
    [self.remoteControllerKey setDelegate:self];
    // Note: This is a workaround for not receiving RC button events, unless we call a remote controller method. 
    [self.remoteController getVersionInfo:^(NSError * _Nullable error, NSString * _Nullable hardwareVersion, NSString * _Nullable firmwareVersion, NSString * _Nullable mcuVersion) {
        NSLog(@"Firmware version is %@", firmwareVersion);
    }];
  }

- (void) scanCameraWifi:(void(^)(NSError * _Nullable error,
                         NSArray<YuneecRemoteControllerCameraWifiInfo *> * _Nullable wifiArray))completionCallback {
    [[MFiRemoteControllerAdapter sharedInstance].remoteController scanCameraWifi:^(NSError * _Nullable error, NSArray<YuneecRemoteControllerCameraWifiInfo *> * _Nullable wifiArray) {
        if(completionCallback != nil) {
            completionCallback(error, wifiArray);
        }
        YuneecRemoteControllerCameraWifiInfo *wifi;
        for (wifi in wifiArray)
            NSLog (@"SSID = %@", wifi.SSID);
    }];
}

- (void) scanAutoPilot:(void(^)(NSError * _Nullable error,
                                 NSArray * _Nullable autoPilotIds))completionCallback {
    [[MFiRemoteControllerAdapter sharedInstance].remoteController scanAutoPilot:^(NSError * _Nullable error, NSArray * _Nullable autoPilotIds) {
        if(completionCallback != nil) {
            completionCallback(error, autoPilotIds);
        }
    }];
}

- (void)bindCameraWifi:(NSString *)wifiSSID
          wifiPassword:(NSString *) wifiPassword
    completionCallback:(void(^)(NSError * _Nullable error))completionCallback {
    [[MFiRemoteControllerAdapter sharedInstance].remoteController bindCameraWifi:wifiSSID
                                                                       password:wifiPassword
                                                                          block:^(NSError * _Nullable error) {
                                                                              if (completionCallback != nil) {
                                                                                  completionCallback(error);
                                                                              }
                                                                          }];
}

- (void) bindAutoPilot:(NSString *)autoPilotId
    completionCallback:(void (^)(NSError * _Nullable error))completionCallback {
    [[MFiRemoteControllerAdapter sharedInstance].remoteController bindAutoPilot:autoPilotId
                                                                          block:^(NSError * _Nullable error) {
                                                                              if (completionCallback != nil) {
                                                                                  completionCallback(error);
                                                                              }
                                                                          }];
}

- (void) unBindCameraWifi:(void(^)(NSError * _Nullable error)) completionCallback {
    [[MFiRemoteControllerAdapter sharedInstance].remoteController unbindCameraWifi:^(NSError * _Nullable error) {
        if(completionCallback != nil) {
            completionCallback(error);
        }
    }];
}

- (void) unBindRC:(void(^)(NSError * _Nullable error)) completionCallback {
    [[MFiRemoteControllerAdapter sharedInstance].remoteController unbindRC:^(NSError * _Nullable error) {
        if(completionCallback != nil) {
            completionCallback(error);
        }
    }];
}

- (void) exitBind:(void(^)(NSError * _Nullable error)) completionCallback {
    [[MFiRemoteControllerAdapter sharedInstance].remoteController exitBind:^(NSError * _Nullable error) {
        if(completionCallback != nil) {
            completionCallback(error);
        }
    }];
}

-(void) getCameraWifiBindStatus:(void(^)(NSError * _Nullable error,
                                YuneecRemoteControllerBindCameraWifiInfo * _Nullable bindWifiInfo))completionCallback {
    [[MFiRemoteControllerAdapter sharedInstance].remoteController getCameraWifiBindStatus:^(NSError * _Nullable error, YuneecRemoteControllerBindCameraWifiInfo * _Nullable bindWifiInfo) {
        if(completionCallback != nil) {
            completionCallback(error, bindWifiInfo);
        }
    }];
}

#pragma mark - YuneecRemoteControllerKeyDelegate

- (void) reportEventInfoUpdateRCCustomKeyEventid:(int)eventid
                                  withEventValue:(int)eventValue {
    if (eventid == CustomKeyLoiterButton || eventid == CustomKeyRTLButton  || eventid == CustomKeyCameraButton || eventid == CustomKeyArmButton || eventid == CustomKeyVideoButton ) {
        currentEventId = eventid;
        currentEventValue = eventValue;
        [self notifyRCEvent];
    }
}

#pragma mark - private methods
- (void) notifyRCEvent {
    NSDictionary* userInfo = @{@"eventId": [self eventIdTypeToString:currentEventId],
                               @"eventValue": @(currentEventValue)
                               };
    if ([NSThread isMainThread]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kRemoteControllerKeyNotification object:nil userInfo:userInfo];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kRemoteControllerKeyNotification object:nil userInfo:userInfo];
        });
    }
}

- (NSString*)eventIdTypeToString:(MFiRemoteControllerEventIDkey)eventId {
    NSString *result = nil;
    
    switch(eventId) {
        case CustomKeyLoiterButton:
            result = @"Loiter Button";
            break;
        case CustomKeyRTLButton:
            result = @"RTL Button";
            break;
        case CustomKeyCameraButton:
            result = @"Camera Button";
            break;
        case CustomKeyArmButton:
            result = @"Arm Button";
            break;
        case CustomKeyVideoButton:
            result = @"Video Button";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected FormatType."];
    }
    
    return result;
}


- (void)firmwareUpdate:(NSString *) filePath
                           progressBlock:(void (^)(float progress)) progressBlock
                         completionBlock:(void (^)(NSError *_Nullable error)) completionBlock
{
    [self.remoteControlFileTransfer transferFirmwareToRemoteController:filePath progressBlock:progressBlock completionBlock:completionBlock];
}

- (void)getFirmwareVersionInfo:(void(^)(NSString * _Nullable firmwareVersion)) completionBlock
{
    [self.remoteController getVersionInfo:^(NSError * _Nullable error, NSString * _Nullable hardwareVersion, NSString * _Nullable firmwareVersion, NSString * _Nullable mcuVersion) {
        if (error != nil) {
            completionBlock(@"Unknown");
            NSLog(@"getRcVersionInfo failed%@", error.localizedDescription);
        } else {
            completionBlock(firmwareVersion);
        }
    }];
}
@end
