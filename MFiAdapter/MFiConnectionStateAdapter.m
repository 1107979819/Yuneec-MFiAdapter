
#import <UIKit/UIKit.h>

#import "MFiConnectionStateAdapter.h"
#import <YuneecDataTransferManager/YuneecDataTransferConnectionState.h>
#import <YuneecDataTransferManager/YuneecDataTransferManager.h>
#import <YuneecDataTransferManager/YuneecControllerDataTransfer.h>

#import <c_library_v2/common/mavlink.h>

#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import <YuneecCameraSDK/YuneecCameraSDK.h>

@interface MFiConnectionStateAdapter() <YuneecDataTransferConnectionStateDelegate, YuneecFlyingControllerDataTransferDelegate, GCDAsyncUdpSocketDelegate>

@property (assign, nonatomic, readwrite) BOOL                       connected;
@property (assign, nonatomic, readwrite) BOOL                       bIsBackground;
@property (assign, nonatomic, readwrite) BOOL                       bIsTcpSocketStart;
@property (assign, nonatomic) YuneecDataTransferConnectionType      connectionType;
@property (strong, nonatomic) YuneecDataTransferConnectionState     *connectionState;

@property (strong, nonatomic) dispatch_source_t     heartbeatTimer;

@end

@implementation MFiConnectionStateAdapter

int numMessagesReceived = 0;
int numHeartbeatsReceived = 0;
int numMessagesSent = 0;
GCDAsyncUdpSocket *udpSocket;

NSString * const kMFiConnectionStateNotification = @"MFiConnectionStateNotification";

#pragma mark - init

+ (instancetype)sharedInstance {
    static MFiConnectionStateAdapter *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[MFiConnectionStateAdapter alloc] init];
    });
    return sInstance;
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        dispatch_queue_t queue = dispatch_queue_create("com.yuneec.udpadapterqueue", DISPATCH_QUEUE_SERIAL);
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue: queue];
        NSError *error = nil;
        if (![udpSocket bindToPort:0 error:&error]) {
            NSLog(@"Error binding: %@", error);
            return self;
        }

        if (![udpSocket beginReceiving:&error])
        {
            [udpSocket close];
            NSLog(@"Error receiving: %@", error);
            return self;
        }
        NSLog(@"Ready");

        // FIXME: remove again
        [self startHeartbeatTimer];

        self.bIsBackground = NO;
        self.bIsTcpSocketStart = NO;
        self.connectionType = YuneecDataTransferConnectionTypeNone;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [[YuneecDataTransferManager sharedInstance] controllerDataTransfer].flyingControllerDelegate = self;

        [self startMonitorConnectionState];
    }
    return self;
}

- (void)dealloc {
    [self stopHeartbeatTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    if (self.bIsTcpSocketStart == YES) {
        [[YuneecMediasDownloadServer sharedInstance] closeTCPSocket];
        self.bIsTcpSocketStart = NO;
    }
    [self stopMonitorConnectionState];
}

- (void)applicationDidEnterBackground {
    self.bIsBackground = YES;
    [self notifyConnectionStateUpdate];
}

- (void)applicationWillEnterForeground {
    self.bIsBackground = NO;
    if((self.connected) && (self.connectionType != YuneecDataTransferConnectionTypeNone)) {
        [self notifyConnectionStateUpdate];
    }
}

#pragma mark - public method

- (void)startMonitorConnectionState {
    [self.connectionState startMonitorConnectionState];
    NSLog(@"connectionState started");
}

- (void)stopMonitorConnectionState {
    [self.connectionState stopMonitorConnectionState];
}

- (BOOL)getMFiConnectionState {
    if(self.connected && (self.connectionType == YuneecDataTransferConnectionTypeMFi)) {
        return YES;
    }
    else {
        return NO;
    }
}

- (NSDictionary *)getConnectionStatus {
    NSDictionary* userInfo = @{@"MFiConnectionState": @(self.connected),
                               @"MFiConnectionType": @(self.connectionType),
                               @"BackgroundState": @(self.bIsBackground),
                               @"DroneMonitorLost":@(self.bDroneMonitorLost),
                               @"NumMessagesReceived":@(numMessagesReceived),
                               @"NumHeartbeatsReceived":@(numHeartbeatsReceived),
                               @"NumMessagesSent":@(numMessagesSent)
                               };
    return userInfo;
}

#pragma mark - YuneecDataTransferConnectionStateDelegate

- (void)connectionState:(YuneecDataTransferConnectionState *) connectionState
   changeConnectionType:(YuneecDataTransferConnectionType) connectionType
               fromType:(YuneecDataTransferConnectionType) fromType
{
    // FIXME: probably use this again
//    if (connectionType != fromType) {
//        if (connectionType == 2) {
//            [self stopHeartbeatTimer];
//        } else if (connectionType == 0) {
//            [self startHeartbeatTimer];
//        }
//    }

    if (connectionType == YuneecDataTransferConnectionTypeMFi) {
        self.connected = YES;
        if (self.bIsTcpSocketStart == NO) {
            [[YuneecMediasDownloadServer sharedInstance] openTCPSocket];
            self.bIsTcpSocketStart = YES;
        }
    } else {
        self.connected = NO;
        if (self.bIsTcpSocketStart == YES) {
            [[YuneecMediasDownloadServer sharedInstance] closeTCPSocket];
            self.bIsTcpSocketStart = NO;
        }
    }
    self.connectionType = connectionType;
    [[YuneecDataTransferManager sharedInstance] setCurrentDataTransferType:connectionType];
    [[YuneecDataTransferManager sharedInstance] setStreamDataTransferType:connectionType];
    
    [self notifyConnectionStateUpdate];
}


#pragma mark - private methods
- (void) notifyConnectionStateUpdate {
    NSDictionary* userInfo = [self getConnectionStatus];
    if ([NSThread isMainThread]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMFiConnectionStateNotification object:nil userInfo:userInfo];
    }
    else {
        // This used to be dispatch_sync but would hang when the MFi session tries
        // to close when the USB cable is removed.
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMFiConnectionStateNotification object:nil userInfo:userInfo];
        });
    }
}

#pragma mark - get & set

- (YuneecDataTransferConnectionState *)connectionState {
    if (_connectionState == nil) {
        _connectionState = [[YuneecDataTransferConnectionState alloc] init];
        _connectionState.connectionDelegate = self;
        NSLog(@"YuneecDataTransferConnectionState initialized");
    }
    return _connectionState;
}

- (void)controllerDataTransfer:(YuneecControllerDataTransfer *) dataTransfer
didReceiveFlyingControllerData:(NSData *) mavlinkData {
    numMessagesReceived++;
    [udpSocket sendData:mavlinkData toHost:@"127.0.0.1" port:14540 withTimeout:-1 tag:0];
    // NSLog(@"Received bytes from controller");
    [self notifyConnectionStateUpdate];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    // NSLog(@"Received bytes from core");
    numMessagesSent++;
    [self notifyConnectionStateUpdate];
    [self sendControllerDataToTransfer:data];
}

- (void)sendHeartbeatPackage {

    // FIXME: change or remove this.
    {
        mavlink_message_t       message;
        mavlink_heartbeat_t     heartbeat;

        heartbeat.custom_mode   = 0;
        heartbeat.type          = MAV_TYPE_GCS;
        heartbeat.autopilot     = MAV_AUTOPILOT_INVALID;
        heartbeat.base_mode     = MAV_MODE_FLAG_MANUAL_INPUT_ENABLED|MAV_MODE_FLAG_SAFETY_ARMED;
        heartbeat.system_status = MAV_STATE_ACTIVE;
        heartbeat.mavlink_version= 3;

        uint16_t package_len = mavlink_msg_heartbeat_encode(1, 240, &message, &heartbeat);

        uint8_t *buf = (uint8_t *)malloc(package_len);
        uint16_t ret = mavlink_msg_to_send_buffer(buf, &message);
    #pragma unused(ret)

        NSData *sendData = [[NSData alloc] initWithBytes:buf length:package_len];
        [udpSocket sendData:sendData toHost:@"127.0.0.1" port:14540 withTimeout:-1 tag:0];
        free(buf);

    }
    numMessagesSent++;
}

- (void)sendControllerDataToTransfer:(NSData *) data {
    [[[YuneecDataTransferManager sharedInstance] controllerDataTransfer] sendData:data];
}

- (void)startHeartbeatTimer {
    if (self.heartbeatTimer != nil) {
        return;
    }
    self.heartbeatTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
    dispatch_source_set_timer(self.heartbeatTimer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0.0);

    dispatch_source_set_event_handler(self.heartbeatTimer, ^{
        [self sendHeartbeatPackage];
    });

    dispatch_resume(self.heartbeatTimer);
}

- (void)stopHeartbeatTimer {
    if (self.heartbeatTimer != nil) {
        dispatch_source_cancel(self.heartbeatTimer);
        self.heartbeatTimer = nil;
    }
}


@end
