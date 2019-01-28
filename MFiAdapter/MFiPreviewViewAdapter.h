//
//  YuneecPreviewViewController.h
//  YuneecPreviewDemo
//
//  Created by tbago on 07/02/2018.
//  Copyright © 2018 yuneec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YuneecPreviewView/YuneecPreviewView.h>

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

@end
