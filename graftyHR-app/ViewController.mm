//
//  ViewController.m
//  GraftyHR-APP
//
//  Created by ben on 12/3/13.
//  Copyright (c) 2013 NSScreencast. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import "ViewController.h"
#include "dlib/image_processing/frontal_face_detector.h"


#ifdef __cplusplus
#import <opencv2/core/core_c.h>
#import <opencv2/opencv.hpp>
#include <hrios/hrios.h>
#include <numeric>
#endif

@interface ViewController () <TopViewLayerDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) dispatch_queue_t sampleQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation ViewController
{
        size_t oldbpm;
        NSTimer *timeToStopTimer;
}

@synthesize camera            = _camera;
@synthesize captureGrayscale  = _captureGrayscale;
@synthesize qualityPreset     = _qualityPreset;
@synthesize captureSession    = _captureSession;
@synthesize captureDevice     = _captureDevice;
@synthesize videoOutput       = _videoOutput;
@synthesize videoPreviewLayer = _videoPreviewLayer;
@synthesize topViewLayer      = _topViewLayer;
@synthesize canStartProcessing= _canStartProcessing;

cv::VideoCapture      cap;
dlib::shape_predictor pose_model;

extern bool Camera;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load the face Haar cascade from resources
    
    NSString * const kFaceCascadeFilename    = @"GraftyResources/haarcascade_frontalface_alt2";
    NSString * const kNoseCascadeFilename    = @"GraftyResources/haarcascade_mcs_nose";
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

    gsys.setFrameRate(30);
    gsys.setProgramState(DETECT);
    
    std::string *predictor_fname = new std::string([shapePredictorPath UTF8String]);
    dlib::deserialize((const std::string) *predictor_fname) >> pose_model;
    
    _camera = 1;   //0 = back camera; 1 = front camera
    _canStartProcessing = false;
    
    // *** these go together ****
    gsys.imageType = GRAFTY_Y_CB_CR; // or GRAFTY_BGRA
    _captureGrayscale = true;
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

static int lightSamp = 0;
- (void)captureOutput:(AVCaptureOutput *)captureOutput
                      didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
                      fromConnection:(AVCaptureConnection *)connection {
    
    
    CFDictionaryRef metadataDictionary = (CFDictionaryRef) CMGetAttachment(sampleBuffer,
                                                                           kCGImagePropertyExifDictionary, NULL);
    NSDictionary *metaDict= (__bridge NSDictionary*)metadataDictionary;
    NSArray *isoDict =          [ metaDict objectForKey:@"ISOSpeedRatings" ];
    NSNumber *iso          = [NSNumber numberWithInt:[ [isoDict objectAtIndex:0] intValue]];
    currentISO = [iso intValue];
    
    float shutterSpeed = [[metaDict objectForKey:@"ShutterSpeedValue"] floatValue];

    
    lightSamp++;
    if(lightSamp>30){
        //printf("iso = %2.2f, shutter = %f, lux = %2.2f, temp = %f\n", currentISO, shutterSpeed, gsys.lux, gsys.temperature);
        lightSamp=0;
    }
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
    CGRect videoRect = CGRectMake(0.0f, 0.0f, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    
    AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)[UIDevice currentDevice].orientation;

    if (format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange){
        // For grayscale mode, the luminance channel of the YUV data is used
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        
        void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        cv::Mat matY(videoRect.size.height, videoRect.size.width, CV_8UC1, baseaddress, 0);
        baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        cv::Mat matCbCr(videoRect.size.height/2, videoRect.size.width/2, CV_8UC2, baseaddress, 0);
        [self processFrameY:matY CbCr:matCbCr videoRect:videoRect videoOrientation:videoOrientation];
        
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
    
    [self createVideoPreviewLayer];
    [self createTextPreviewLayer];
    
    return YES;
}

- (void) createVideoPreviewLayer
{
    // Create a video preview layer
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setFrame:[[UIScreen mainScreen] bounds]];
    
    //[AN] change from Aspect to AspectFill
    // AVLayerVideoGravityResizeAspect;
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer insertSublayer:_videoPreviewLayer atIndex:0];
}

- (void) createTextPreviewLayer
{
    //create a text preview layer
    CATextLayer *tLayer = nil;
    tLayer = [[CATextLayer alloc] init];
    tLayer.name = @"bpm";
    tLayer.string = @"";
    tLayer.backgroundColor  = [UIColor darkGrayColor].CGColor;
    tLayer.foregroundColor  = tColor;
    tLayer.frame = CGRectMake(self.view.bounds.origin.x,self.view.bounds.origin.y+20,self.view.bounds.size.width,20);
    tLayer.font = (__bridge CFTypeRef)@"AmericanTypewriter-CondensedLight";
    tLayer.fontSize = 20;
    tLayer.alignmentMode = kCAAlignmentCenter;
    tLayer.contentsScale = [[UIScreen mainScreen] scale];
    [self.view.layer insertSublayer:tLayer above:_videoPreviewLayer];
}

static CGColorRef tColor = [UIColor whiteColor].CGColor;
GraftySystem       gsys;
GraftyFaceList     faces;
clock_t tin, tout = 0;
float realFPS = 0;
std::deque<float> fpsHist;
static void * const MyAdjustingExposureObservationContext = (void*)&MyAdjustingExposureObservationContext;

CGPoint exposurePoint = CGPointMake(0.5f, 0.5f);
static bool iso_setting_in_progress = false;
static bool temperature_setting_in_progress = false;
static float targetISO        = 0;
static float currentISO;


- (void)processFrameY:(cv::Mat &)matY CbCr:(cv::Mat)matCbCr videoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
    Camera = true;
    
    //if user didn't click on circle to start processing or user click to stop processing, we should stop processing the frames.
    if(!_canStartProcessing)
    {
        _topViewLayer.circleProgressWithLabel.progress = 0.0f;
        _topViewLayer.circleProgressWithLabel.progressColor = [UIColor orangeColor];
        _topViewLayer.infoLabel.text =  @"Position face in the circle..";

        [self stopHR];
        return;
    }
    
    
    switch (videoOrientation) {
        case AVCaptureVideoOrientationPortrait:
        {
            cv::transpose(matY, matY);
            cv::transpose(matCbCr, matCbCr);
            break;
        }
        case AVCaptureVideoOrientationLandscapeLeft:
        {
            break;
        }
        case AVCaptureVideoOrientationLandscapeRight:
        {
            cv::flip(matY, matY, -1);
            cv::flip(matCbCr, matCbCr, -1);
            break;
        }
        case AVCaptureVideoOrientationPortraitUpsideDown:
        {
            cv::transpose(matY, matY);
            cv::flip(matY, matY, -1);
            cv::transpose(matCbCr, matCbCr);
            cv::flip(matCbCr, matCbCr, -1);
            break;
        }
            
    }
   
    if ( gsys.getProgramState() == DETECT &&
        [_captureDevice lockForConfiguration:NULL] == YES ) {
        
        if ([_captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [_captureDevice setExposurePointOfInterest:exposurePoint];
            [_captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        
        if ([_captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
        {
            [_captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        }
        
        [_captureDevice unlockForConfiguration];
        targetISO = currentISO;
        iso_setting_in_progress = false;
        //calibrate_attempt_count = 0;
        gsys.camState = CAM_AUTO;
    }

    //******
    gsys.setCurrentFrame(matY, matCbCr);
    trigger_hr(gsys, faces, pose_model);

    size_t bpm = 0;

    if (faces.size())
    {
        // cancel stopHR timer if any
        if(timeToStopTimer)
        {
            if([timeToStopTimer isValid])
            {
                NSLog(@"face detected..15 sec timer cancelled");
                [timeToStopTimer invalidate];
                timeToStopTimer = nil;
            }
        }
        
        if (gsys.getProgramState() == TRACK_UPDATE ||
            gsys.getProgramState() == TRACK_MAINTAIN)
        {
            faces[0].getBpm(gsys, bpm);
            realFPS = (float)faces[0].getFPS();
//            NSLog(@"realFPS = %f", realFPS);
            if (realFPS < 20) {
                bpm = 0;
            }
        }
        else if (gsys.getProgramState() == TRACK_INIT)
        {
            cv::Rect2f bbox;
            create_bounding_box_from_points(faces[0].nextNosePoints, bbox);
            bbox = [ self pixelBuffer2Display:bbox pixelFrame:cv::Rect2f(0,0, gsys.nFrame.cols, gsys.nFrame.rows)];
            
            cv::Point2f fpoint_cv = cv::Point2f(bbox.x + bbox.width/2.0f, bbox.y + bbox.height/2.0f);
            
            
            // https://developer.apple.com/library/mac/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/04_MediaCapture.html
            // CGPoint should be from (0,0) to (1,1) with (0,0) at top left and (1,1) at bottom right in landscape right position
            // refer to Focus modes in the documentation above
            CGPoint     fpoint_cg = CGPointMake((float)(fpoint_cv.y/self.view.bounds.size.height),
                                                (float)(self.view.bounds.size.width - fpoint_cv.x)/self.view.bounds.size.width
                                                );
            exposurePoint = fpoint_cg;
            
            float lux  = 0.0f;
            float temperature = 3000.0f;
            gsys.calculateLux(faces[0].nextGFPoints, lux, temperature);
            [self calibrateCamera:lux temp:(float)temperature];
        }
    }
    else {
        //kick off startHR timer since there is no face detected.
        // if there is no face within 15 sec, shut it down
        if (!timeToStopTimer) {
            
            if (![NSThread isMainThread]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    timeToStopTimer = [NSTimer scheduledTimerWithTimeInterval:15.0f target:self selector:@selector(timerHandler:) userInfo:nil repeats:NO];
                });
            }
            else {
                timeToStopTimer = [NSTimer  scheduledTimerWithTimeInterval:15.0f target:self selector:@selector( timerHandler:) userInfo:nil repeats:NO];
            }
        }
    }
    
    cv::Rect2f bbox;
    if (gsys.getProgramState() == TRACK_UPDATE) {
        create_bounding_box_from_points(faces[0].nextGFPoints, bbox);
        bbox = [ self pixelBuffer2Display:bbox pixelFrame:cv::Rect2f(0,0, gsys.nFrame.cols, gsys.nFrame.rows) ];
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
               displayFps: (size_t) realFPS

         ];
    });
}

int displayProgressCount = 0;
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
        
        if ([[currentLayer name] isEqualToString:@"bpm"]) {
            tLayer = (CATextLayer *)currentLayer;
        }
    }

    CGRect faceRect;
    faceRect.origin.x    = bbox.x;
    faceRect.origin.y    = bbox.y;
    faceRect.size.width  = bbox.width;
    faceRect.size.height = bbox.height;
    
    
    if (!featureLayer) {
        // Create a new feature marker layer
        featureLayer = [[CALayer alloc] init];
        featureLayer.name = @"FaceLayer";
        featureLayer.borderColor = [[UIColor greenColor] CGColor];
        featureLayer.borderWidth = 1.0f;
        [self.view.layer addSublayer:featureLayer];
    }
    featureLayer.frame = faceRect;
    [featureLayer setHidden:YES];

    
    if (!tLayer) {
        // Create a new bpm marker layer
        tLayer = [[CATextLayer alloc] init];
        tLayer.name = @"bpm";
        tLayer.backgroundColor  = [UIColor darkGrayColor].CGColor;
        tLayer.foregroundColor  = [UIColor whiteColor].CGColor;
        tLayer.frame = CGRectMake(self.view.bounds.origin.x,self.view.bounds.origin.y+20,self.view.bounds.size.width,40);
        tLayer.font = (__bridge CFTypeRef)@"AmericanTypewriter-CondensedLight";
        tLayer.fontSize = 12;
        tLayer.alignmentMode = kCAAlignmentLeft;
        tLayer.contentsScale = [[UIScreen mainScreen] scale];
        [self.view.layer insertSublayer:tLayer above:_videoPreviewLayer];
    }
//    NSString *label = [NSString stringWithFormat:@"BPM:%zu FPS:%zu %s",
//                       (size_t) (bpm), (size_t) fps, progressString.c_str()];
//    tLayer.string = label;
    [tLayer setHidden:YES];
    
    if (gsys.getProgramState() == DETECT) {
        _topViewLayer.circleProgressWithLabel.progressColor = [UIColor orangeColor];
        _topViewLayer.circleProgressWithLabel.progress = 1;
        
        _topViewLayer.infoLabel.text =  @"Position face in the circle..";
        
        
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
        
        _topViewLayer.infoLabel.text =  @"Hold Still..";
        [self updateUpdateLabel:@""  showHeart:NO];
        
        if(nil != _topViewLayer.heart)
        {
            _topViewLayer.heart.text = @"";
            _topViewLayer.bPMResult.text =  [NSString stringWithFormat:@""];
        }
    }
    else if (gsys.getProgramState() == TRACK_INIT){
        _topViewLayer.circleProgressWithLabel.progressColor = [UIColor orangeColor];
        _topViewLayer.circleProgressWithLabel.progress = 1;
        
        _topViewLayer.infoLabel.text =  @"Calibrating..";
        [self updateUpdateLabel:@""  showHeart:NO];
        
        if(nil != _topViewLayer.heart)
        {
            _topViewLayer.heart.text = @"";
            _topViewLayer.bPMResult.text =  [NSString stringWithFormat:@""];
        }
    }
    else if (gsys.getProgramState() == TRACK_UPDATE)
    {
        NSString *lightCondition = subOptimalLight ? @"poor light" : @"good light";
        float trackingPercentage = faces[0].getHRTrackingPercentage()*100;
        
        _topViewLayer.infoLabel.text =  [NSString stringWithFormat:@"Estimating BPM [%2.0f fps, %@]", realFPS, lightCondition];

            //[_topViewLayer updateCircleLabel:[NSString stringWithFormat:@"%zu",(size_t) (bpm)]];
            if(bpm <= 0)//we don't need to show zero bpm for user so instead we will say "Estimating.."
            {
                if(oldbpm > 0)
                {
                    if(nil != _topViewLayer.heart)
                    {
                        //_topViewLayer.heart.text = @"♥";
                        _topViewLayer.bPMResult.text =  [NSString stringWithFormat:@""];
                        _topViewLayer.infoLabel.text =  [NSString stringWithFormat:@"Estimating [%2.0f fps, %@]", realFPS, lightCondition];
                        //[self updateUpdateLabel:@"CALCULATING..." showHeart:NO];
                    }
                }
            }
            else
            {
                oldbpm = bpm;
                if(nil == _topViewLayer.heart)
                {
                    _topViewLayer.infoLabel.text =  [NSString stringWithFormat:@"Estimating [%2.0f fps, %@]", realFPS, lightCondition];
                    [self updateUpdateLabel:  [NSString stringWithFormat:@"%zu bpm",(size_t)(bpm)]  showHeart:YES];
                }
                else {
                    _topViewLayer.infoLabel.text =  [NSString stringWithFormat:@"Estimating [%2.0f fps, %@]", realFPS, lightCondition];
                    _topViewLayer.heart.text = @"♥";
                    _topViewLayer.bPMResult.text =  [NSString stringWithFormat:@"%zu\nbpm",(size_t)(bpm)];
                    [self updateUpdateLabel:@""  showHeart:NO];
                }
            }
        if (displayProgressCount < 15) {
            displayProgressCount++;
        }
        else
        {
            displayProgressCount = 0;
           _topViewLayer.circleProgressWithLabel.progressColor = [UIColor greenColor];
           _topViewLayer.circleProgressWithLabel.progress = trackingPercentage/100.0;
        }
    }
    else {
        _topViewLayer.infoLabel.text =  @"Error, try again..";
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == MyAdjustingExposureObservationContext)
    {
        // Do  stuff
    }

}

- (cv::Rect2f) pixelBuffer2Display:(cv::Rect2f)inRect pixelFrame:(cv::Rect2f)pixelFrame
{
    cv::Rect2f R;
    
    size_t viewH = self.view.bounds.size.height;
    size_t viewW = self.view.bounds.size.width;
    
    float viewToMatMinRatio = std::min(viewH, viewW)/std::min(pixelFrame.height, pixelFrame.width);
    float viewToMatMaxRatio = std::max(viewH, viewW)/std::max(pixelFrame.height, pixelFrame.width);
    
    if (self.view.bounds.size.height >= self.view.bounds.size.width)
    {
        R.x    = inRect.x*viewToMatMinRatio;
        R.y    = inRect.y*viewToMatMaxRatio;
        R.width  = inRect.width*viewToMatMinRatio;
        R.height = inRect.height*viewToMatMaxRatio;
    }
    else {
        R.x    = inRect.x*viewToMatMaxRatio;
        R.y    = inRect.y*viewToMatMinRatio;
        R.width  = inRect.width*viewToMatMaxRatio;
        R.height = inRect.height*viewToMatMinRatio;
    }
    return R;
}

#define MIN_ISO              40   // must be greater than activeFormat.minISO
#define MAX_ISO             500   // must be less than activeFormat.maxISO

// match up the vector below with the values above
//standard ISO values: 50, 64, 80, 100, 125, 160, 200, 250, 320, 400, 500, 640
static std::vector<float> std_iso = {   40.0f, 50.0f,  64.0f,  80.0f, 100.0f, 125.0f, 160.0f,
                                       200.0f, 250.0f, 320.0f, 400.0f, 500.0f, 640.0f, 800.0f
};

#define MIN_SHUTTER_SPEED   125
#define MAX_SHUTTER_SPEED     1

static int calibrate_attempt_count = 0;
bool       subOptimalLight = false;

- (void) calibrateCamera:(float)lux temp:(float)temperature
{
    if (iso_setting_in_progress || temperature_setting_in_progress)
    {
        return;
    }
    
    NSLog(@"Calibrate attempt count = %d", calibrate_attempt_count);
    if (calibrate_attempt_count++ >= 30)
    {
        subOptimalLight = true;
        printf("Calibration failed.. locking cam anyway\n");
        
        tColor = [UIColor yellowColor].CGColor;
        gsys.camState = CAM_LOCKED;
        calibrate_attempt_count = 0;
    }
    
   // CMTime shutterSpeed = CMTimeMake(1,125) ;
    CMTime shutterSpeed = AVCaptureExposureDurationCurrent ;
    
    if (currentISO > MAX_ISO) {
        targetISO = MAX_ISO;
    }
    else if (currentISO < MIN_ISO) {
        targetISO = MIN_ISO;
    }
    else if (lux < 100) {
        targetISO = [self nextUpISO:currentISO ];
    }
    else if (lux > 150)
    {
        targetISO = [self nextDownISO:currentISO ];
    }
    else if (std::abs(targetISO - currentISO) <= 10)
    {
        gsys.camState = CAM_LOCKED;
        calibrate_attempt_count = 0;
    }
    

    if (
        [_captureDevice lockForConfiguration:NULL] == YES ) {
        
        if ([_captureDevice isExposureModeSupported:AVCaptureExposureModeCustom]) {
            iso_setting_in_progress = true;
            [_captureDevice setExposureModeCustomWithDuration:shutterSpeed ISO:targetISO completionHandler:^(CMTime syncTime)
             
            {
                iso_setting_in_progress = false;
            }
             
             ];
            
            temperature = 7000 - temperature;
            
            if (temperature < 2500) temperature = 2500.0f;
            if (temperature > 7000) temperature = 7000.0f;
            
            AVCaptureWhiteBalanceTemperatureAndTintValues temperatureAndTint = {
                .temperature = 3000,
                .tint = 0,
            };
            
            temperature_setting_in_progress = true;
            [_captureDevice deviceWhiteBalanceGainsForTemperatureAndTintValues:temperatureAndTint];
            [_captureDevice setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:[_captureDevice deviceWhiteBalanceGainsForTemperatureAndTintValues:temperatureAndTint] completionHandler:^(CMTime syncTime)
            {
                temperature_setting_in_progress = false;
            }];
        }
        [_captureDevice unlockForConfiguration];
    }
    else {
        printf("[NO ACTION] lux = %2.2f, currentISO = %2.2f, targetISO = %2.2f\n", lux, currentISO, targetISO);
    }
}

- (void) lockCamera
{
    if ( [_captureDevice isExposureModeSupported:AVCaptureExposureModeLocked ] &&
         [_captureDevice lockForConfiguration:NULL] == YES ) {
        
        [_captureDevice setExposureMode:AVCaptureExposureModeLocked];
        [_captureDevice unlockForConfiguration];

    }
}

- (float) nextUpISO:(float)inISO
{
    float nextISO = inISO;
    if (inISO < std_iso.front())
    {
        nextISO = std_iso.front();
    }
    else if (inISO >= std_iso.back())
    {
        nextISO = std_iso.back();
    }
    else
    {
        for (int i = 0; i < std_iso.size() - 1; i++)
        {
            if ( inISO >= std_iso[i] && inISO < std_iso[i+1] )
            {
                nextISO = std_iso[i+1];
                break;
            }
        }
    }
    return (nextISO);
}

- (float) nextDownISO:(float)inISO
{

    float nextISO = inISO;
    if (inISO <= std_iso.front())
    {
        nextISO = std_iso.front();
    }
    else if (inISO > std_iso.back())
    {
        nextISO = std_iso.back();
    }
    else
    {
        for (int i = 0; i < std_iso.size() - 1; i++)
        {
            if ( inISO <= std_iso[i+1] && inISO > std_iso[i] )
            {
                nextISO = std_iso[i];
                break;
            }
        }
    }
    return (nextISO);
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
        if( [[UIDevice currentDevice] orientation] == UIDeviceOrientationFaceUp  ||
            [[UIDevice currentDevice] orientation] == UIDeviceOrientationFaceDown
          )
        {
            // CGRect frm = screenFrame;
            if(screenFrame.size.width>screenFrame.size.height)
            {
               // screenFrame=CGRectMake(frm.origin.x, frm.origin.y, frm.size.height, frm.size.width);
                 _topViewLayer = [[TopViewLayerLandScapeLeft alloc] initWithFrame:screenFrame];
            }
            else{
                 _topViewLayer = [[TopViewLayer alloc] init];
            }
        }
        else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ||
                 [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight)
        {
           
            CGRect frm = screenFrame;
            if(screenFrame.size.height > screenFrame.size.width)
            {
                // parameters are x,y,width,height
                // here we are swapping width and height to gurantee that display is correct in the case where
                // orientation is updated but screen information is not yet updated
                screenFrame=CGRectMake(frm.origin.x, frm.origin.y, frm.size.height, frm.size.width);
            }
            _topViewLayer = [[TopViewLayerLandScapeLeft alloc] initWithFrame:screenFrame];
        }
        else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait ||
                 [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown
                )
        {
            CGRect frm = screenFrame;
            if(screenFrame.size.width > screenFrame.size.height)
            {
                // parameters are x,y,width,height
                // here we are swapping width and height to gurantee that display is correct in the case where
                // orientation is updated but screen information is not yet updated
                screenFrame=CGRectMake(frm.origin.x, frm.origin.y, frm.size.height, frm.size.width);
                _topViewLayer = [ [TopViewLayer alloc] initWithFixedFrame:screenFrame];
            }
            else
            {
                _topViewLayer = [[TopViewLayer alloc] init];
            }
        }
        
    }
    _topViewLayer.delegate  = self;
    [self.view addSubview:_topViewLayer];
    [self.view bringSubviewToFront:_topViewLayer];
}

NSInteger orientation = UIDeviceOrientationUnknown;

-(void)orientationChanged:(NSNotification*)notification
{
    UIDevice * device = notification.object;
    
    switch(device.orientation)
    {
        
        case UIDeviceOrientationFaceUp:
            /* start special animation */
            NSLog(@"UIDeviceOrientationFaceUp");
            if (orientation != device.orientation)
            {
                orientation = device.orientation;
                [self viewWillLayoutSubviews];
                [self stopHR];
                [self addTopViewLayer];
            }
            break;

        case UIDeviceOrientationPortrait:
            /* start special animation */
            NSLog(@"UIDeviceOrientationPortrait");
            if (orientation != device.orientation)
            {
                orientation = device.orientation;
                [self viewWillLayoutSubviews];
                [self stopHR];
               [self addTopViewLayer];
            }
            break;
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationPortraitUpsideDown:
            /* start special animation */
            NSLog(@"UIDeviceOrientationPortraitUpsideDown");
            if (orientation != device.orientation)
            {
                orientation = device.orientation;
                [self viewWillLayoutSubviews];
                [self stopHR];
                [self addTopViewLayer];
            }
            break;
        case UIDeviceOrientationLandscapeLeft:
            NSLog(@"UIDeviceOrientationLandscapeLeft");
            if (orientation != device.orientation)
            {
                orientation = device.orientation;
                [self viewWillLayoutSubviews];
                [self stopHR];
                [self addTopViewLayer];
            }
            break;
        case UIDeviceOrientationLandscapeRight:
            NSLog(@"UIDeviceOrientationLandscapeRight");
            if (orientation != device.orientation)
            {
                orientation = device.orientation;
                [self viewWillLayoutSubviews];
                
                [self stopHR];
                [self addTopViewLayer];
            }
            break;
        default:
            break;
    };
}

-(void)toggleStartStopProcess
{
    NSLog(@"canstart toggled from %d to %d", _canStartProcessing, !_canStartProcessing);
    _canStartProcessing = !_canStartProcessing;
    //add the toast to infor user to what to do to either start or stop the processing.
    if(_canStartProcessing)
    {
        [ self startHR ];
    }
    else
    {
        [ self stopHR ];
    }
}



-(void)timerHandler:(NSTimer*)theTimer
{
    [self stopHR];
}

-(void)stopHR
{
    gsys.setProgramState(DETECT);
    _canStartProcessing = false;
    subOptimalLight = false;

    
    
    CALayer     *featureLayer = nil;
    NSArray *sublayers = [NSArray arrayWithArray:[self.view.layer sublayers]];
    NSUInteger sublayersCount = [sublayers count];
    NSUInteger currentSublayer = 0;
    while (!featureLayer && (currentSublayer < sublayersCount)) {
        CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
        if ([[currentLayer name] isEqualToString:@"FaceLayer"]) {
            featureLayer = currentLayer;
        }
    }
    [featureLayer setHidden:YES];


    if(timeToStopTimer)
    {
        if([timeToStopTimer isValid])
        {
            NSLog(@"timer canceled from stopHR");
            [timeToStopTimer invalidate];
            timeToStopTimer = nil;
        }
    }
    [self showTapMeToStart];
}

-(void)startHR
{
    _canStartProcessing = true;

    //stop any previous timer running.
    if(timeToStopTimer)
    {
        if([timeToStopTimer isValid])
        {
            [timeToStopTimer invalidate];
            timeToStopTimer = nil;
        }
    }
    
    // hide middle circle..
    [UIView animateWithDuration:0.5 animations:^{
        _topViewLayer.middleCircleView.hidden=YES;
    } completion:^(BOOL finished) {
        //[self performSelector:@selector(showTapAgainToStop) withObject:nil afterDelay:0.5];
        //            timeToStopTimer = [NSTimer  scheduledTimerWithTimeInterval:30 target:self selector:@selector(toggleStartStopProcess) userInfo:nil repeats:NO];
    }];
}



#pragma -mark TopViewLayer Delegate
-(void)circleProgressClicked:(id)sender{
    
//    NSUserDefaults * defaultUser = [NSUserDefaults standardUserDefaults];
    
//    if( nil != [defaultUser objectForKey:@"showFaceOutLine"])
//    {
//        [defaultUser setObject:[NSNumber numberWithBool:NO] forKey:@"showFaceOutLine"];
//        [defaultUser synchronize];
//    }
    
    if(timeToStopTimer)
    {
        if([timeToStopTimer isValid])
        {
            [timeToStopTimer invalidate];
            timeToStopTimer = nil;
        }
    }
    [self toggleStartStopProcess];
    
}

-(void)showTapAgainToStop
{
    //show tap again to stop
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionRepeat animations:^{
        _topViewLayer.tapToStartLabel.text=@"Tap again to stop";
        //_topViewLayer.middleCircleView.backgroundColor =[UIColor clearColor];
        _topViewLayer.middleCircleView.hidden=NO;
        [_topViewLayer.tapToStartLabel setNeedsDisplay];
    } completion:^(BOOL finished) {
        [self performSelector:@selector(hideTapAgainToStop) withObject:nil afterDelay:1];
    }];
    
}

-(void)hideTapAgainToStop
{
    //
    [UIView animateWithDuration:0.5 delay:1.0 options:UIViewAnimationOptionRepeat animations:^{
        
        _topViewLayer.middleCircleView.hidden=YES;
        [_topViewLayer.tapToStartLabel setNeedsDisplay];
    } completion:^(BOOL finished) {
        
    }];
}

-(void)showTapMeToStart
{
    //show tap me to start
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionRepeat animations:^{
        _topViewLayer.tapToStartLabel.text=@"Tap to start...";
        _topViewLayer.middleCircleView.hidden=NO;
        [_topViewLayer.tapToStartLabel setNeedsDisplay];
    } completion:^(BOOL finished) {
        //
    }];
    
}

#pragma -mark Fixing camera orientation
-(BOOL)shouldAutorotate
{
    return YES;
}
-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    
}
- (void)viewWillLayoutSubviews {
    _videoPreviewLayer.frame = self.view.bounds;
    if (_videoPreviewLayer.connection.supportsVideoOrientation) {
        _videoPreviewLayer.connection.videoOrientation = [self interfaceOrientationToVideoOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }
}

- (AVCaptureVideoOrientation)interfaceOrientationToVideoOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIDeviceOrientationFaceUp:
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIDeviceOrientationFaceDown:
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        default:
            break;
    }
    NSLog(@"Warning - Didn't recognise interface orientation (%d)",orientation);
    return AVCaptureVideoOrientationPortrait;
}

@end
