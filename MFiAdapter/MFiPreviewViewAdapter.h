//
//  YuneecPreviewViewController.h
//  YuneecPreviewDemo
//
//  Created by tbago on 07/02/2018.
//  Copyright © 2018 yuneec. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <YuneecPreviewView/YuneecPreviewView.h>

// weakSelf
#ifndef WS
#define WS(weakSelf)  __weak __typeof(self) weakSelf = self
#endif

/// This interface provides methods to display live video stream from camera
@interface MFiPreviewViewAdapter : NSObject

/**
 * Singleton object
 *
 * @return MFiPreviewViewAdapter singleton instance
 */
+ (instancetype _Nonnull )sharedInstance;

/**
 * Start live video stream from the camera
 *
 */
- (void) startVideo:(YuneecPreviewView *)previewView
 completionCallback:(void(^_Nullable)(NSString * _Nullable error))completionCallback;

/**
 * Stop live video stream from the camera
 *
 */
- (void) stopVideo:(void(^_Nullable)(NSString * _Nullable error))completionCallback;

/**
 * update live video stream display window
 *
 */
- (void) updateDisplayRect:(CGRect) DisplayRect;

@end
