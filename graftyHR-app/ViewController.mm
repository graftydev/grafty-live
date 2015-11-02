//
//  ViewController.m
//  GraftyVPDemo
//
//  Created by ben on 12/3/13.
//  Copyright (c) 2013 NSScreencast. All rights reserved.
//

#import "ViewController.h"
#import "TopViewLayerSettings.h"

#include "dlib/image_processing/frontal_face_detector.h"
#include "dlib/image_processing/render_face_detections.h"

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#include <hrios/hrios.h>
#include <numeric>
#endif

@interface ViewController ()<TopViewLayerDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) dispatch_queue_t sampleQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation ViewController
{
    size_t oldbpm;
}
@synthesize camera            = _camera;
@synthesize captureGrayscale  = _captureGrayscale;
@synthesize qualityPreset     = _qualityPreset;
@synthesize captureSession    = _captureSession;
@synthesize captureDevice     = _captureDevice;
@synthesize videoOutput       = _videoOutput;
@synthesize videoPreviewLayer = _videoPreviewLayer;
@synthesize topViewLayer      =_topViewLayer;
@synthesize canStartProcessing=_canStartProcessing;

cv::VideoCapture   cap;
dlib::shape_predictor pose_model;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load the face Haar cascade from resources
    
    NSString * const kFaceCascadeFilename = @"GraftyResources/haarcascade_frontalface_alt2";
    NSString * const kNoseCascadeFilename = @"GraftyResources/haarcascade_mcs_nose";
    NSString * const kShapePredictorFileName = @"GraftyResources/shape_predictor_68_face_landmarks";

    
    NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:kFaceCascadeFilename ofType:@"xml"];
    NSString *noseCascadePath = [[NSBundle mainBundle] pathForResource:kNoseCascadeFilename ofType:@"xml"];
    NSString *shapePredictorPath = [[NSBundle mainBundle] pathForResource:kShapePredictorFileName ofType:@"dat"];

    
    std::string faceCascadeFname = [faceCascadePath UTF8String];
    if (!gsys.loadFaceCascade(faceCascadeFname)) {
        NSLog(@"Could not load face cascade: %@", faceCascadePath);
    }
    
    std::string noseCascadeFname = [noseCascadePath UTF8String];
    if (!gsys.loadNoseCascade(noseCascadeFname)) {
        NSLog(@"Could not load nose cascade: %@", noseCascadePath);
    }
    
    std::string *predictor_fname = new std::string([shapePredictorPath UTF8String]);
    dlib::deserialize((const std::string) *predictor_fname) >> pose_model;
    

    gsys.setFrameRate(30);
    gsys.setProgramState(DETECT);
    _camera = 1;   //0 = back camera; 1 = front camera
    
    // **************************
    // these go together ****
    gsys.imageType = GRAFTY_Y_CB_CR; // GRAFTY_BGRA, GRAFTY_Y_CB_CR;
    _captureGrayscale = true;        //   false for GRAFTY_BGRA; true to GRAFTY_Y_CB_CR
    // **************************
    [self createCaptureSessionForCamera:_camera qualityPreset:_qualityPreset grayscale:_captureGrayscale];
    [_captureSession startRunning];
    
    //track device orientation
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
    
}


- (AVCaptureDevice *)frontCamera {
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
                      didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
                      fromConnection:(AVCaptureConnection *)connection {
    
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
    CGRect videoRect = CGRectMake(0.0f, 0.0f, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)[UIDevice currentDevice].orientation;
    
    if (format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        // For grayscale mode, the luminance channel of the YUV data is used
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        
        void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        cv::Mat mat(videoRect.size.height, videoRect.size.width, CV_8UC1, baseaddress, 0);
        [self processFrame:mat videoRect:videoRect videoOrientation:videoOrientation];
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
    else if (format == kCVPixelFormatType_32BGRA) {
        // For color mode a 4-channel cv::Mat is created from the BGRA data
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        
        void *baseaddress = CVPixelBufferGetBaseAddress(pixelBuffer);
        cv::Mat mat(videoRect.size.height, videoRect.size.width, CV_8UC4, baseaddress, 0);
        [self processFrame:mat videoRect:videoRect videoOrientation:videoOrientation];
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
    else {
        NSLog(@"Unsupported video format");
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
                      didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer
                      fromConnection:(AVCaptureConnection *)connection {
    
}

// MARK: Private methods

// Sets up the video capture session for the specified camera, quality and grayscale mode
//
//
// camera: -1 for default, 0 for back camera, 1 for front camera
// qualityPreset: [AVCaptureSession sessionPreset] value
// grayscale: YES to capture grayscale frames, NO to capture RGBA frames
//
- (BOOL)createCaptureSessionForCamera:(NSInteger)camera qualityPreset:(NSString *)qualityPreset grayscale:(BOOL)grayscale
{
    // Set up AV capture
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    if ([devices count] == 0) {
        NSLog(@"No video capture devices found");
        return NO;
    }
    
    if (camera == -1) {
        _camera = -1;
        _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    else if (camera >= 0 && camera < [devices count]) {
        _camera = camera;
        _captureDevice = [devices objectAtIndex:camera];
    }
    else {
        _camera = -1;
        _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        NSLog(@"Camera number out of range. Using default camera");
    }
    
    NSError *error = nil;
    CMTime frameDuration = CMTimeMake(1, 30);
    NSArray *supportedFrameRateRanges = [_captureDevice.activeFormat videoSupportedFrameRateRanges];
    BOOL frameRateSupported = NO;
    for (AVFrameRateRange *range in supportedFrameRateRanges) {
        if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) &&
            CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
            frameRateSupported = YES;
        }
    }
    
    if (frameRateSupported && [_captureDevice lockForConfiguration:&error]) {
        [_captureDevice setActiveVideoMaxFrameDuration:frameDuration];
        [_captureDevice setActiveVideoMinFrameDuration:frameDuration];
        [_captureDevice unlockForConfiguration];
    }
    
    // Create the capture session
    _captureSession = [[AVCaptureSession alloc] init];
    _captureSession.sessionPreset = (qualityPreset)? qualityPreset : AVCaptureSessionPreset640x480;
    //_captureSession.sessionPreset = (qualityPreset)? qualityPreset : AVCaptureSessionPresetMedium;

    
    // Create device input
    error = nil;
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:_captureDevice error:&error];
    
    // Create and configure device output
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    

    dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
    [_videoOutput setSampleBufferDelegate:self queue:queue];
    
    
    // For grayscale mode, the luminance channel from the YUV fromat is used
    // For color mode, BGRA format is used
    OSType format = kCVPixelFormatType_32BGRA;
    
    
    // Check YUV format is available before selecting it (iPhone 3 does not support it)
    if (grayscale && [_videoOutput.availableVideoCVPixelFormatTypes containsObject:
                      [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]]) {
        format = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    }
    
    _videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:format]
                                                             forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    // Connect up inputs and outputs
    if ([_captureSession canAddInput:input]) {
        [_captureSession addInput:input];
    }
    
    if ([_captureSession canAddOutput:_videoOutput]) {
        [_captureSession addOutput:_videoOutput];
    }
    
    // Create a video preview layer
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _videoPreviewLayer.delegate = self;
    
    //[AN] fixed to take screen bounds
    [_videoPreviewLayer setFrame:[[UIScreen mainScreen] bounds]];
    
    //[AN] change from Aspect to AspectFill
    // AVLayerVideoGravityResizeAspect;

    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.view.layer insertSublayer:_videoPreviewLayer atIndex:0];
    return YES;
}

GraftySystem       gsys;
GraftyFaceList     faces;
std::deque<float> fpsHist;
clock_t tin, tout = 0;
float fps = 0;

- (void)processFrame:(cv::Mat &)mat videoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
    //if user didn't click on circle to start processing or user click to stop processing, we should stop processing the frames.
    if(!_canStartProcessing)
        return;
    
    switch (videoOrientation) {
        case AVCaptureVideoOrientationPortrait:
        {
            cv::transpose(mat, mat);
            break;
        }
        case AVCaptureVideoOrientationLandscapeLeft:
        {
            break;
        }
        case AVCaptureVideoOrientationLandscapeRight:
        {
            cv::flip(mat, mat, -1);
            break;
        }
        case AVCaptureVideoOrientationPortraitUpsideDown:
        {
            cv::transpose(mat, mat);
            cv::flip(mat, mat, -1);
            break;
        }
            
    }
   
    //******    Call into Library to get bpm ****
    gsys.setCurrentFrame(mat);
    trigger_hr(gsys, faces, pose_model);
    //******    Done                         ****

    size_t bpm = 0;
    if (faces.size())
    {
        faces[0].getBpm(gsys, bpm);
        float avgFps = (float)faces[0].getFPS();
        if (avgFps < 20) {
            bpm = 0;
        } else
        {
            if (avgFps > 20 && avgFps <25 ) {
                bpm = bpm * (25.0f/30.0f);
            } else {
                bpm = bpm * ((float)faces[0].getFPS()/30.0f);
            }
            
            if (bpm>1 && bpm < 55) {
                bpm = 55;
            }
        }
    }
    
    int fpsAvg = 0;
    if (faces.size())
    {
        fpsAvg = faces[0].getFPS();
    }
    
    tout = 0;
    cv::Rect2f bbox;
    if (gsys.getProgramState() == TRACK_UPDATE) {
        create_bounding_box_from_points(faces[0].nextPoints, bbox);
    }
    else {
        bbox.x = bbox.y = 0;
        bbox.width = 0;
        bbox.height = 0;
    }
    
    // Dispatch updating of face markers to main queue
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self displayFace:bbox
             forVideoRect:rect
         videoOrientation:videoOrientation
               displayBpm:bpm
               displayFps: (size_t) fpsAvg
         ];
    });
}

// Update face markers given vector of face rectangles
- (void)displayFace:(const cv::Rect &)bbox
       forVideoRect:(CGRect)rect
   videoOrientation:(AVCaptureVideoOrientation)videoOrientation
         displayBpm:(size_t)bpm
         displayFps:(float)fps
{
    NSArray *sublayers = [NSArray arrayWithArray:[self.view.layer sublayers]];
    int sublayersCount = [sublayers count];
    int currentSublayer = 0;
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    // hide all the face layers
    for (CALayer *layer in sublayers) {
        NSString *layerName = [layer name];
        if ([layerName isEqualToString:@"FaceLayer"])
            [layer setHidden:YES];
    }
    
    CALayer     *featureLayer = nil;
    CATextLayer *tLayer = nil;

    while (!featureLayer && (currentSublayer < sublayersCount)) {
        CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
        if ([[currentLayer name] isEqualToString:@"FaceLayer"]) {
            featureLayer = currentLayer;
        }
        
        if ([[currentLayer name] isEqualToString:@"spm"]) {
            tLayer = (CATextLayer *)currentLayer;
        }
    }
    
    size_t viewH = self.view.bounds.size.height;
    size_t viewW = self.view.bounds.size.width;
    
    float viewToMatMinRatio = std::min(viewH, viewW)/std::min(rect.size.height, rect.size.width);
    float viewToMatMaxRatio = std::max(viewH, viewW)/std::max(rect.size.height, rect.size.width);

    CGRect faceRect;

    if(bbox.width != 0 )
    {
        if (self.view.bounds.size.height >= self.view.bounds.size.width)
        {
            faceRect.origin.x    = bbox.x*viewToMatMinRatio;
            faceRect.origin.y    = bbox.y*viewToMatMaxRatio;
            faceRect.size.width  = bbox.width*viewToMatMinRatio;
            faceRect.size.height = bbox.height*viewToMatMaxRatio;
        }
        else {
            faceRect.origin.x    = bbox.x*viewToMatMaxRatio;
            faceRect.origin.y    = bbox.y*viewToMatMinRatio;
            faceRect.size.width  = bbox.width*viewToMatMaxRatio;
            faceRect.size.height = bbox.height*viewToMatMinRatio;
        }
        
        if (!featureLayer) {
            // Create a new feature marker layer
            featureLayer = [[CALayer alloc] init];
            featureLayer.name = @"FaceLayer";
            featureLayer.borderColor = [[UIColor greenColor] CGColor];
            featureLayer.borderWidth = 1.0f;
            [self.view.layer addSublayer:featureLayer];
        }
        featureLayer.frame = faceRect;
        [featureLayer setHidden:YES];//[AN] set to hide

    }
    
    if (gsys.getProgramState() == DETECT) {
        _topViewLayer.circleProgressWithLabel.progressColor = [UIColor orangeColor];
        _topViewLayer.circleProgressWithLabel.progress = 1;
        
        _topViewLayer.infoLabel.text =  @"POSITION FACE IN THE CIRCLE";
        
        
        [self updateUpdateLabel:@"" showHeart:NO];
        
        if(oldbpm > 0)
        {
            //_topViewLayer.updateLabel.text =  [NSString stringWithFormat:@"HOLD STILL\n♥ %zu bpm",(size_t)(oldbpm)];
            if(nil == _topViewLayer.heart)
            {
                
                [self updateUpdateLabel:[NSString stringWithFormat:@"%zu bpm (last)",(size_t)(oldbpm)] showHeart:YES];
            }
            else {
                _topViewLayer.heart.text = @"♥";
                _topViewLayer.bPMResult.text =  [NSString stringWithFormat:@"%zu\nbpm (last)",(size_t)(oldbpm)];
               [self updateUpdateLabel:@""  showHeart:NO];
            }
        }
        //[_topViewLayer updateCircleLabel:@""];
    } else if (gsys.getProgramState() == TRACK_MAINTAIN ) {
        _topViewLayer.circleProgressWithLabel.progressColor = [UIColor orangeColor];
        _topViewLayer.circleProgressWithLabel.progress = 1;
        
        _topViewLayer.infoLabel.text =  @"";
        [self updateUpdateLabel:@"HOLD STILL"  showHeart:NO];
        
        if(nil != _topViewLayer.heart)
        {
            _topViewLayer.heart.text = @"";
            _topViewLayer.bPMResult.text =  [NSString stringWithFormat:@""];
        }
    }
    
    if (faces.size())
    {
        float trackingPercentage = faces[0].getHRTrackingPercentage()*100;
        if(trackingPercentage < 100)
        {
            
            [self updateUpdateLabel:@"HOLD STILL"  showHeart:NO];
            if(nil != _topViewLayer.heart)
            {
                _topViewLayer.heart.text = @"";
                _topViewLayer.bPMResult.text =  [NSString stringWithFormat:@""];
            }
        }
        else{
            //[_topViewLayer updateCircleLabel:[NSString stringWithFormat:@"%zu",(size_t) (bpm)]];
            if(bpm <= 0)//we don't need to show zero bpm for user so instead we will say Still Calculating
            {
                [self updateUpdateLabel:@"CALCULATING..."  showHeart:NO];
                
                if(oldbpm > 0)
                {
                    if(nil != _topViewLayer.heart)
                    {
                        //_topViewLayer.heart.text = @"♥";
                        _topViewLayer.bPMResult.text =  [NSString stringWithFormat:@""];
                       [self updateUpdateLabel:@"CALCULATING..." showHeart:NO];
                    }
                }
            }
            else
            {
                oldbpm = bpm;
                if(nil == _topViewLayer.heart)
                {
                   [self updateUpdateLabel:  [NSString stringWithFormat:@"%zu bpm",(size_t)(bpm)]  showHeart:YES];
                }
                else {
                    _topViewLayer.heart.text = @"♥";
                    _topViewLayer.bPMResult.text =  [NSString stringWithFormat:@"%zu\nbpm",(size_t)(bpm)];
                  [self updateUpdateLabel:@""  showHeart:NO];
                }
            }
        }
        _topViewLayer.circleProgressWithLabel.progressColor = [UIColor greenColor];
        _topViewLayer.circleProgressWithLabel.progress = trackingPercentage/100.0;
    }
    [CATransaction commit];
}


- (CGAffineTransform)affineTransformForVideoFrame:(CGRect)videoFrame orientation:(AVCaptureVideoOrientation)videoOrientation
{
    
    // Move origin to center so rotation and scale are applied correctly
    CGAffineTransform t;
    switch (videoOrientation) {
        case AVCaptureVideoOrientationPortrait:
            t = CGAffineTransformMakeTranslation(-videoFrame.size.height / 2.0f, -videoFrame.size.width / 2.0f);
            t = CGAffineTransformConcat(t, CGAffineTransformMake(1, 0, 0, -1, 0, 0));
            
            break;
            
        case AVCaptureVideoOrientationPortraitUpsideDown:
            t = CGAffineTransformMakeTranslation(-videoFrame.size.height / 2.0f, -videoFrame.size.width / 2.0f);
            t = CGAffineTransformConcat(t, CGAffineTransformMakeRotation(M_PI));
            //widthScale = viewSize.width / videoFrame.size.width;
            //heightScale = viewSize.height / videoFrame.size.height;
            break;
            
        case AVCaptureVideoOrientationLandscapeRight:
            t = CGAffineTransformMakeTranslation(-videoFrame.size.width / 2.0f, -videoFrame.size.height / 2.0f);
            
            t = CGAffineTransformConcat(t, CGAffineTransformMakeRotation(-M_PI_2));
            // widthScale = viewSize.width / videoFrame.size.height;
            // heightScale = viewSize.height / videoFrame.size.width;
            break;
            
        case AVCaptureVideoOrientationLandscapeLeft:
            t = CGAffineTransformMakeTranslation(-videoFrame.size.width / 2.0f, -videoFrame.size.height / 2.0f);
            
            break;
    }
    
    // Move origin back from center
    t = CGAffineTransformConcat(t, CGAffineTransformMakeTranslation(videoFrame.size.width / 2.0f, videoFrame.size.height / 2.0f));
    
    return t;
}

-(void)updateUpdateLabel:(NSString*)value showHeart:(BOOL)showHeart
{
    
    if(nil == _topViewLayer.updateHeartLabel)
    {
        _topViewLayer.updateLabel.text =  value;
    }
    else
    {
         _topViewLayer.updateHeartLabel.label.text=value;
        if( [value isEqualToString:@""])
            _topViewLayer.updateHeartLabel.heart.text=@"";
        else
        {
            if(showHeart)
                _topViewLayer.updateHeartLabel.heart.text=@"♥";
            else
                _topViewLayer.updateHeartLabel.heart.text=@"";
        }
    }
   
}
-(void)addTopViewLayer
{
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    
    if( nil != _topViewLayer)
    {
        [_topViewLayer removeFromSuperview];
        _topViewLayer = nil;
    }
    
    if(nil == _topViewLayer)
    {
        if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait)
        {
            _topViewLayer = [[TopViewLayer alloc] init];
        }
        else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft)
        {
        _topViewLayer = [[TopViewLayerLandScapeLeft alloc] initWithFrame:screenFrame];
        
        }
        else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight)
        {
            _topViewLayer = [[TopViewLayerLandScapeRight alloc] initWithFrame:screenFrame];
        }
        else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown)
        {
            _topViewLayer = [[TopViewLayerPortraitUpSideDown alloc] initWithFrame:screenFrame];
        }
    }
    _topViewLayer.delegate  = self;
    [self.view addSubview:_topViewLayer];
    [self.view bringSubviewToFront:_topViewLayer];
}

-(void)orientationChanged:(NSNotification*)notification
{
    UIDevice * device = notification.object;
    switch(device.orientation)
    {
        case UIDeviceOrientationPortrait:
            /* start special animation */
            [self addTopViewLayer];
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            /* start special animation */
            NSLog(@"UIDeviceOrientationPortraitUpsideDown");
             [self addTopViewLayer];
            break;
        case UIDeviceOrientationLandscapeLeft:
            NSLog(@"UIDeviceOrientationLandscapeLeft");
             [self addTopViewLayer];
            break;
        case UIDeviceOrientationLandscapeRight:
            NSLog(@"UIDeviceOrientationLandscapeRight");
             [self addTopViewLayer];
            break;
        default:
            break;
    };
}

#pragma -mark TopViewLayer Delegate
-(void)circleProgressClicked:(id)sender{
    _canStartProcessing = !_canStartProcessing;
    //add the tost to infor user to what to do to either start or stop the processing.
    if(_canStartProcessing)
    {
        [UIView animateWithDuration:0.5 animations:^{
            //hid tap me to start
             _topViewLayer.tapToStartLabel.hidden=YES;
        } completion:^(BOOL finished) {
            [self performSelector:@selector(showTapAgainToStop) withObject:nil afterDelay:0.5];
            
        }];
    }
    else
    {
        [self showTapMeToStart];
    }
    
}
-(void)showTapAgainToStop
{
    //show tap again to stop
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionRepeat animations:^{
        _topViewLayer.tapToStartLabel.text=@"Tap again to stop";
        _topViewLayer.tapToStartLabel.hidden=NO;
        [_topViewLayer.tapToStartLabel setNeedsDisplay];
    } completion:^(BOOL finished) {
        [self performSelector:@selector(hideTapAgainToStop) withObject:nil afterDelay:1];
    }];

}
-(void)hideTapAgainToStop
{
    //
    [UIView animateWithDuration:0.5 delay:1.0 options:UIViewAnimationOptionRepeat animations:^{
        
        _topViewLayer.tapToStartLabel.hidden=YES;
        [_topViewLayer.tapToStartLabel setNeedsDisplay];
    } completion:^(BOOL finished) {
        
    }];
}
-(void)showTapMeToStart
{
    //show tap me to start
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionRepeat animations:^{
        _topViewLayer.tapToStartLabel.text=@"Tap me to start...";
        _topViewLayer.tapToStartLabel.hidden=NO;
        [_topViewLayer.tapToStartLabel setNeedsDisplay];
    } completion:^(BOOL finished) {
        //
    }];

}

@end
