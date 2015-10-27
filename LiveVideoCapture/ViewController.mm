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

@interface ViewController ()

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) dispatch_queue_t sampleQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation ViewController

@synthesize camera            = _camera;
@synthesize captureGrayscale  = _captureGrayscale;
@synthesize qualityPreset     = _qualityPreset;
@synthesize captureSession    = _captureSession;
@synthesize captureDevice     = _captureDevice;
@synthesize videoOutput       = _videoOutput;
@synthesize videoPreviewLayer = _videoPreviewLayer;
@synthesize topViewLayer      =_topViewLayer;
cv::VideoCapture   cap;
dlib::shape_predictor pose_model;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load the face Haar cascade from resources
    
    NSString * const kFaceCascadeFilename = @"GraftyResources/haarcascade_frontalface_alt2";
    NSString * const kNoseCascadeFilename = @"GraftyResources/haarcascade_mcs_nose";
    //NSString * const kVideoFileName       = @"GraftyResources/IMG_0024";
    //NSString * const kVideoFileName         = @"HR_003_1_4_(127,153)_40";
    
    NSString * const kShapePredictorFileName = @"GraftyResources/shape_predictor_68_face_landmarks";

    
    NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:kFaceCascadeFilename ofType:@"xml"];
    NSString *noseCascadePath = [[NSBundle mainBundle] pathForResource:kNoseCascadeFilename ofType:@"xml"];
    // *videoPath = [[NSBundle mainBundle] pathForResource:kVideoFileName ofType:@"MOV"];
    NSString *shapePredictorPath = [[NSBundle mainBundle] pathForResource:kShapePredictorFileName ofType:@"dat"];

    
    std::string faceCascadeFname = [faceCascadePath UTF8String];
    if (!gsys.loadFaceCascade(faceCascadeFname)) {
        NSLog(@"Could not load face cascade: %@", faceCascadePath);
    }
    
    std::string noseCascadeFname = [noseCascadePath UTF8String];
    if (!gsys.loadNoseCascade(noseCascadeFname)) {
        NSLog(@"Could not load nose cascade: %@", noseCascadePath);
    }
    
    //cap = cv::VideoCapture ([videoPath UTF8String]);
    //if (!cap.isOpened()) { return; }

    gsys.setFrameRate(30);
    gsys.setProgramState(DETECT);
    
    std::string *predictor_fname = new std::string([shapePredictorPath UTF8String]);

    dlib::deserialize((const std::string) *predictor_fname) >> pose_model;
    
    _camera = 1;   //0 = back camera; 1 = front camera
    
    // *** these go together ****
    gsys.imageType = GRAFTY_Y_CB_CR; // or GRAFTY_BGRA
    _captureGrayscale = true;  // or false
    // **************************
    [self createCaptureSessionForCamera:_camera qualityPreset:_qualityPreset grayscale:_captureGrayscale];
    [_captureSession startRunning];
    
    [self addTopViewLayer];
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
    //AVCaptureVideoOrientation videoOrientation = [[[_videoOutput connections] objectAtIndex:0] videoOrientation];
    AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)[UIDevice currentDevice].orientation;
    
    //    NSLog(@"Orientation = %d", (int) videoOrientation);
    
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
    
    //[_videoPreviewLayer setFrame:self.view.bounds];
    //[AN] fixed to take screen bounds
    [_videoPreviewLayer setFrame:[[UIScreen mainScreen] bounds]];
    
    //[AN] change from Aspect to AspectFill
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    // AVLayerVideoGravityResizeAspect;
    
    
    
    [self.view.layer insertSublayer:_videoPreviewLayer atIndex:0];
    
    //create a text preview layer
    CATextLayer *tLayer = nil;
    tLayer = [[CATextLayer alloc] init];
    tLayer.name = @"spm";
    tLayer.string = @"";
    tLayer.backgroundColor  = [UIColor blackColor].CGColor;
    tLayer.foregroundColor  = [UIColor yellowColor].CGColor;
    tLayer.frame = CGRectMake(self.view.bounds.origin.x,self.view.bounds.origin.y+20,self.view.bounds.size.width,20);
    tLayer.font = (__bridge CFTypeRef)@"AmericanTypewriter-CondensedLight";
    tLayer.fontSize = 20;
    tLayer.alignmentMode = kCAAlignmentCenter;
    tLayer.contentsScale = [[UIScreen mainScreen] scale];
    [self.view.layer insertSublayer:tLayer above:_videoPreviewLayer];
    
    return YES;
}

GraftySystem       gsys;
GraftyFaceList     faces;
clock_t tin, tout = 0;
float fps =0;
std::deque<float> fpsHist;
//std::deque<std::chrono::time_point<std::chrono::high_resolution_clock>> clockVector;


- (void)processFrame:(cv::Mat &)mat videoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
    
    //cap >> mat;

    
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
   
    //******
    gsys.setCurrentFrame(mat);
    tin = clock();
    trigger_hr(gsys, faces, pose_model);

//    size_t spm = 0.0f;
    size_t bpm = 0;

//    float  motionStrengthX = 0.0f, motionStrengthY = 0.0f;
//    float  phiYaw = -0xFFFFFFFF, thetaPitch = -0xFFFFFFFF;
    if (faces.size())
    {
        //        faces[0].getSpm(gsys, spm, motionStrengthX, motionStrengthY);
        //        faces[0].getFacePose(phiYaw, thetaPitch);
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
            
            if (bpm>1 && bpm < 60) {
                bpm = 60;
            }
        }
    }
    
    
    tout = tout + clock() - tin;
    double secs_between_frames = (double)(tout)/(CLOCKS_PER_SEC);
    
//    fps = 1.0f/secs_between_frames;
//    if (fps < 100) {
//       fpsHist.push_back(fps);
//    }
//    
//    if (fpsHist.size() > 30) {
//        fpsHist.pop_front();
//    }
//    
//    int fpsAvg = (std::accumulate(fpsHist.begin(), fpsHist.end(), 0))/fpsHist.size();
    int fpsAvg =0;
    if (faces.size())
    {
        fpsAvg = faces[0].getFPS();
    }
    
    tout = 0;
    
    //NSLog(@"fps=%zu", (size_t) fps);
    
    //NSLog(@"fps=%f, spm = %d, bpm = %d, phiYaw = %f, theta = %f, motionX = %f, motionY = %f", fps, (int) spm, (int) bpm, phiYaw, thetaPitch, motionStrengthX, motionStrengthY);
    //******
    
    cv::Rect2f bbox;
    if (gsys.getProgramState() == TRACK_UPDATE) {
//        create_bounding_box_from_points(faces[0].nextGFPoints, bbox);
        create_bounding_box_from_points(faces[0].nextPoints, bbox);
       // bbox = faces[0].noseRect;
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
//               displaySpm:0 //spm
               displayBpm:bpm
               displayFps: (size_t) fpsAvg
//               displayPhi:0 //phiYaw
//             displayTheta:0 //thetaPitch
//           displayMotionX:0 //motionStrengthX
//           displayMotionY:0 //motionStrengthY
         ];
    });
}

// Update face markers given vector of face rectangles
- (void)displayFace:(const cv::Rect &)bbox
       forVideoRect:(CGRect)rect
   videoOrientation:(AVCaptureVideoOrientation)videoOrientation
//         displaySpm:(size_t)spm
         displayBpm:(size_t)bpm
         displayFps:(float)fps
//         displayPhi:(float)phi
//       displayTheta:(float)theta
//     displayMotionX:(float)motionStrengthX
//     displayMotionY:(float)motionStrengthY

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
        
        //       if ([layerName isEqualToString:@"spm"])
        //           [layer setHidden:YES];
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
        [featureLayer setHidden:NO];

    }
    
    if (!tLayer) {
        // Create a new spm marker layer
        tLayer = [[CATextLayer alloc] init];
        tLayer.name = @"spm";
        tLayer.backgroundColor  = [UIColor blackColor].CGColor;
        tLayer.foregroundColor  = [UIColor yellowColor].CGColor;
        tLayer.frame = CGRectMake(self.view.bounds.origin.x,self.view.bounds.origin.y+20,self.view.bounds.size.width,40);
        tLayer.font = (__bridge CFTypeRef)@"AmericanTypewriter-CondensedLight";
        tLayer.fontSize = 12;
        tLayer.alignmentMode = kCAAlignmentLeft;
        tLayer.contentsScale = [[UIScreen mainScreen] scale];
        [self.view.layer insertSublayer:tLayer above:_videoPreviewLayer];
    }
//    NSString *label = [NSString stringWithFormat:@"FPS: %5.2f SPM: %zu BPM: %zu Yaw: %5.2f Pitch: %5.2f MotionX: %5.2f MotionY: %5.2f",
    
    std::string progressString;
    float trackingPercentage = 0.0f;
    progressString = ".....";

    if (faces.size())
    {
        float trackingPercentage = faces[0].getHRTrackingPercentage()*100;
        if(trackingPercentage <100)
        {
            //[_topViewLayer updateCircleLabel:@""];
            _topViewLayer.updateLabel.text =  @"HOLD POSITION";
        }
        
        if ( trackingPercentage < 20) {
            progressString = ".....";
        }
        else if (trackingPercentage>=20 && trackingPercentage < 40){
            progressString = "*....";
        }
        else if (trackingPercentage>=40 && trackingPercentage < 60){
            progressString = "**...";
        }
        else if (trackingPercentage>=60 && trackingPercentage < 80){
            progressString = "***..";
        }
        else if (trackingPercentage>=80 && trackingPercentage < 100){
            progressString = "****.";
        }
        else{
            progressString = "*****";
            
            //[_topViewLayer updateCircleLabel:[NSString stringWithFormat:@"%zu",(size_t) (bpm)]];
            _topViewLayer.updateLabel.text =  [NSString stringWithFormat:@"CURRENT HEARTRATE \n♥\n%zu\nBPM",(size_t)(bpm)];
        }
        _topViewLayer.circleProgressWithLabel.progressColor = [UIColor greenColor];
        _topViewLayer.circleProgressWithLabel.progress = trackingPercentage/100.0;
        
    }
    
   
    
    if (gsys.getProgramState() == 3 || gsys.getProgramState() == 1) {
        progressString = "Hold Still";
        _topViewLayer.circleProgressWithLabel.progressColor = [UIColor orangeColor];
        _topViewLayer.circleProgressWithLabel.progress = 1;
        
        _topViewLayer.infoLabel.text =  @"POSITION FACE IN THE CIRCLE";
        _topViewLayer.updateLabel.text =  @"HOLD STILL";
        
         //[_topViewLayer updateCircleLabel:@""];
    }

    NSString *label = [NSString stringWithFormat:@"BPM = %zu, FPS = %zu, %s",
                       (size_t) (bpm), (size_t) fps, progressString.c_str()];
    tLayer.string = label;
    [tLayer setHidden:NO];

    
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



-(void)addTopViewLayer
{
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    
    
    if(nil == _topViewLayer)
    {
        _topViewLayer = [[TopViewLayer alloc] initWithFrame:screenFrame];
        //_topViewLayer.backgroundColor   =[TopViewLayerSettings backGroundColor];
        
        [self.view addSubview:_topViewLayer];
        [self.view bringSubviewToFront:_topViewLayer];
        
    }
    
}


@end
