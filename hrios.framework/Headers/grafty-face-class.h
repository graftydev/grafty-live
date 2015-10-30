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
#include "grafty-core-breath-rate.h"

#include "dlib/image_processing.h"
#include "dlib/dir_nav.h"

#define  TRACK_REJECTION_THRESHOLD      -15


class Face {
    
public:
        //iFace points
    cv::Rect_<float>          iFaceRect;
    float                     iFaceRadius;
    std::vector<cv::Point2f>  iFacePoints;
    
    //initialized good feature variables
    std::vector<cv::Point2f>  iGFPoints;
    size_t                    iNumGFPoints;

    //iNose points
    cv::Rect_<float>                iNoseRect;
    float                     iNoseRadius;
    
    std::vector<cv::Point2f>  iNosePoints;
    std::vector<bool>         iNosePointFlags;
    size_t                    iNumNosePoints;
    
    //iHR points
    cv::Rect_<float>          iHRRect;
    float                     iHRRadius;
    
    std::vector<cv::Point2f>  iHRPoints;
    std::vector<bool>         iHRPointFlags;
    size_t                    iNumHRPoints;
    
    //Face tracking points - prev/next
    std::vector<cv::Point2f>  prevPoints;
    std::vector<cv::Point2f>  nextPoints;
    cv::Rect_<float>                faceRect;

    // good feature tracking points - prev/next
    std::vector<cv::Point2f>  prevGFPoints;
    std::vector<cv::Point2f>  nextGFPoints;
    
    // Nose tracking points previous
    std::vector<bool>         prevNosePointFlags;
    std::vector<cv::Point2f>  prevNosePoints;
    size_t                    numPrevNosePoints;
    
    // Nose tracking points next
    std::vector<bool>         nextNosePointFlags;
    std::vector<cv::Point2f>  nextNosePoints;
    size_t                    numNextNosePoints;
    
    cv::Rect_<float>          noseRect;

    
    // HR tracking points previous
    std::vector<bool>         prevHRPointFlags;
    std::vector<cv::Point2f>  prevHRPoints;
    size_t                    numPrevHRPoints;
    
    // HR tracking points next
    std::vector<bool>         nextHRPointFlags;
    std::vector<cv::Point2f>  nextHRPoints;
    size_t                    numNextHRPoints;

    cv::Rect_<float>                HRRect;
    
    dlib::correlation_tracker tracker;
    int                       isTracking;
    

    // add a pedometer
    Pedometer                 pedometer;
    size_t                    spm;
    float                     motionStrengthX;
    float                     motionStrengthY;
   
    // add a heart rate monitor 
    HeartRate                 heartRate;
    size_t                    bpm;
    
    BreathRate                breathRate;
    size_t                    rpm;
    

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
    void getRPM(GraftySystem& gsys, size_t& rpm);
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
    bool isTracked_gf(void);
    int getTrackingThreshold_gf(void);
    void setTrackingTreshold_fg(int);
    void decrementTrackingThreshold_gf(void);
    
    inline float getFPS(){
        return heartRate.getFPS();
    }
    inline float getHRTrackingPercentage(){
        return heartRate.getTrackingPercentage();
    }
    
    bool getFaceBox(cv::Rect2f &rect);
    
#if GRAFTY_DEBUG == true
public:
    cv::Rect_<float> correlationBox;
#endif
};

typedef std::vector<Face> GraftyFaceList;





#endif /* defined(__grafty_vp__grafty_face_class__) */
