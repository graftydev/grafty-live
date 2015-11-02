//
//  ViewController.h
//  GraftyVPDemo
//
//  Created by ben on 12/3/13.
//  Copyright (c) 2013 NSScreencast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "TopViewLayer.h"
#import "TopViewLayerLandScapeLeft.h"
#import "TopViewLayerLandScapeRight.h"
#import "TopViewLayerPortraitUpSideDown.h"

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>

// AVFoundation components
@property (nonatomic, readonly) AVCaptureSession           *captureSession;
@property (nonatomic, readonly) AVCaptureDevice            *captureDevice;
@property (nonatomic, readonly) AVCaptureVideoDataOutput   *videoOutput;
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;

//Top View Layer
@property (nonatomic, strong) TopViewLayer                 *topViewLayer;

// -1: default, 0: back camera, 1: front camera
@property (nonatomic, assign) int camera;

// These should only be modified in the initializer
@property (nonatomic, assign) NSString * const qualityPreset;
@property (nonatomic, assign) BOOL             captureGrayscale;


// misc
@property (nonatomic, assign) BOOL canStartProcessing;
@end
