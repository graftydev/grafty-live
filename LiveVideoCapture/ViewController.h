//
//  ViewController.h
//  GraftyVPDemo
//
//  Created by ben on 12/3/13.
//  Copyright (c) 2013 NSScreencast. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>

// AVFoundation components
@property (nonatomic, readonly) AVCaptureSession           *captureSession;
@property (nonatomic, readonly) AVCaptureDevice            *captureDevice;
@property (nonatomic, readonly) AVCaptureVideoDataOutput   *videoOutput;
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;


// -1: default, 0: back camera, 1: front camera
@property (nonatomic, assign) int camera;

// These should only be modified in the initializer
@property (nonatomic, assign) NSString * const qualityPreset;
@property (nonatomic, assign) BOOL             captureGrayscale;

@end
