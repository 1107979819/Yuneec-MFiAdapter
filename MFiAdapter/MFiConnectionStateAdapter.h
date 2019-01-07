//
//  MFiConnectionStateAdapter.h
//
//  Created by tbago on 2017/9/8.
//  Copyright © 2017年 yuneec. All rights reserved.
//
#import <Foundation/Foundation.h>

///Add observer to this notification to get MFi connection updates.
extern NSString * const kMFiConnectionStateNotification;

/// This interface provides methods to monitor MFiConnection
@interface MFiConnectionStateAdapter : NSObject;

/**
 * Singleton object
 *
 * @return MFiConnectionStateAdapter singleton instance
 */
+ (instancetype)sharedInstance;

/**
 * Start monitor connection state.
 */
- (void)startMonitorConnectionState;

/**
 * Stop monitor connection state.
 */
- (void)stopMonitorConnectionState ;

/**
 * Get MFi connection state.
 *
 * @return True if connected, else returns false
 */
- (BOOL)getMFiConnectionState;

/**
 * Get Connection status.
 *
 * @return Dictionary containing connection status
 */
- (NSDictionary *)getConnectionStatus;

/**
 * This variable indicates the MFi connection state.
 * True for connected and false for not connected
 */
@property (nonatomic, assign, readonly) BOOL connected;
/**
 * This variable indicates the connection state with the vehicle.
 * True for connected and false for not connected
 */
@property (nonatomic, assign, readonly) BOOL bDroneMonitorLost;
@end
