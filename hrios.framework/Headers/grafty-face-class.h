//
//  grafty-face-class.h
//  grafty-hr
//
//  Created by Manish Mukherjee on 7/4/15.
//  Copyright (c) 2015 Grafty. All rights reserved.
//

#ifndef __grafty_vp__grafty_face_class__
#define __grafty_vp__grafty_face_class__

#include <stdio.h>
#include <math.h>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/video/tracking.hpp>
#include "grafty-core-pedometry.h"
#include "grafty-core-heart-rate.h"

#include "dlib/image_processing.h"
#include "dlib/dir_nav.h"

#define  TRACK_REJECTION_THRESHOLD      -15


class Face {
    
public:
    cv::Rect2f                iFaceRect;
    float                     iFaceRadius;
    std::vector<cv::Point2f>  iFacePoints;
    
    //initialized good feature variables
    std::vector<cv::Point2f>  iGFPoints;
    std::vector<bool>         iGFPointFlags;
    size_t                    iNumGFPoints;

    
    cv::Rect2f                iNoseRect;
    float                     iNoseRadius;
    
    std::vector<cv::Point2f>  iNosePoints;
    std::vector<bool>         iNosePointFlags;
    size_t                    iNumNosePoints;
    
    //for upper lip
    cv::Rect2f                iUpperLipRect;
    std::vector<bool>         iUpperLipFlags;
    std::vector <cv::Point2f> iUpperLipPoints;
    size_t                    iNumUpperLipPoints;
    
    //for lower lip
    cv::Rect2f                  iLowerLipRect;
    std::vector<bool>           iLowerLipFlags;
    std::vector <cv::Point2f>   iLowerLipPoints;
    size_t                      iNumLowerLipPoints;

    std::vector<cv::Point2f>  prevPoints;
    std::vector<cv::Point2f>  nextPoints;
    
    // previous good feature variables
    std::vector<bool>         prevGFPointFlags;
    std::vector<cv::Point2f>  prevGFPoints;
    // next good feature variables
    std::vector<bool>         nextGFPointFlags;
    std::vector<cv::Point2f>  nextGFPoints;
    
    // nose previous
    std::vector<bool>         prevNosePointFlags;
    std::vector<cv::Point2f>  prevNosePoints;
    size_t                    numPrevNosePoints;
    
    // nose next
    std::vector<bool>         nextNosePointFlags;
    std::vector<cv::Point2f>  nextNosePoints;
    size_t                    numNextNosePoints;
    
    
    // upper lip prev
    std::vector<bool>         prevUpperLipFlags;
    std::vector<cv::Point2f>  prevUpperLipPoints;
    size_t                    numPrevUpperLipPoints;
    
    // upper lip next
    std::vector<bool>         nextUpperLipFlags;
    std::vector<cv::Point2f>  nextUpperLipPoints;
    size_t                    numNextUpperLipPoints;

    // lower lip prev
    std::vector<bool>         prevLowerLipFlags;
    std::vector<cv::Point2f>  prevLowerLipPoints;
    size_t                    numPrevLowerLipPoints;
    
    // lower lip next
    std::vector<bool>         nextLowerLipFlags;
    std::vector<cv::Point2f>  nextLowerLipPoints;
    size_t                    numNextLowerLipPoints;

    
    dlib::correlation_tracker       tracker;

    cv::Rect2f                faceRect;
    cv::Rect2f                noseRect;
    cv::Rect2f                lowerLipRect;
    cv::Rect2f                upperLipRect;

    int                       isTracking;
    
    // add isTracking_gf for the good feature tracker
    int                       isTracking_gf;

    // add a pedometer
    Pedometer                 pedometer;
    size_t                    spm;
    float                     motionStrengthX;
    float                     motionStrengthY;
   
    // add a heart rate monitor 
    HeartRate                 heartRate;
    size_t                    bpm;
    

    // include all the methods
    Face (void);
    void clearTracking(void);
    void initiateTracking(void);
    void maintainTrack(void);

    
    void swap(void);
    void savePoints(void);
    
    

    void drawNoseDot(cv::Mat& frame);
    void plotInitialTrackingBox(cv::Mat& im);
    
    
    
    void getSpm(GraftySystem& gsys, size_t& spm, float& motionStrengthX, float& motionStrengthY);
    void getBpm(GraftySystem& gsys, size_t& bpm);
    void getFacePose(float& phiYaw, float& thetaPitch);
    bool isTracked(void);
    int  getTrackingThreshold(void);
    void setTrackingThreshold(int);
    void decrementTrackingThreshold(void);
    
    /////////////////////////////////
    // good feature all the methods
    void clearTracking_gf(void);
    void initiateTracking_gf(void);
    void maintainTrack_gf(void);
    
    void swap_gf(void);
    void savePoints_gf(void);
    
    void drawDots_gf(cv::Mat& frame);
    void plotinitialTrackingBox_gf(cv::Mat& im);
    
    
    void getSpm_gf(GraftySystem& gsys, size_t& spm, float& motionStrengthX, float& motionStrengthY);
    void getBPM_gf(GraftySystem& gsys, size_t& bpm);
    bool isTracked_gf(void);
    int getTrackingThreshold_gf(void);
    void setTrackingTreshold_fg(int);
    void decrementTrackingThreshold_gf(void);
};

typedef std::vector<Face> GraftyFaceList;




#endif /* defined(__grafty_vp__grafty_face_class__) */
