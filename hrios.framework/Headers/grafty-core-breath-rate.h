//
//  grafty-core-breath-rate.h
//  grafty-hr
//
//  Created by Manish Mukherjee on 9/16/15.
//  Copyright (c) 2015 Grafty. All rights reserved.
//

#ifndef __grafty_vp__grafty_core_breathrate__
#define __grafty_vp__grafty_core_breathrate__

#include <stdio.h>
#include <chrono>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/video/tracking.hpp>
#include "grafty-core-utils.h"
#include "grafty-system-settings.h"

#define RPM_VALID       1
#define RPM_NOT_VALID   !BPM_VALID

#define LOWEST_RPM      55.0f //40.0f
#define HIGHEST_RPM     200.0f

#define NUM_OF_FEATURES 3  //7

#define NUM_OF_SAMPLE_TO_AVERAGE 600


class BreathRate {
    
    int                bufferVectorIndex   = 0;
    int                positiveBufferCount = 0;
    int                bufferVectorLength  = 0;
    int                filterDelay = 600; // 224 for a 2 sec buffer length, and augmented 8 times.
    
    bool               RPM_inited = false;
    
    size_t             numFramesPerBreathRate;
    
    size_t             numHRCalculationsPerSec = 4;
    
    std::deque<size_t> rpmHistory;

    std::deque<float>  bufferVector;
    
    std::vector<std::deque<float>> bufferFeatures;
    
    size_t numFeatures =NUM_OF_FEATURES;
    
    size_t numOfSampleToAverage = NUM_OF_SAMPLE_TO_AVERAGE;

    
    
    float              rpm2Hz[2]    = { LOWEST_RPM/60.0f, HIGHEST_RPM/60.0f }; // Define the bandpass frequencies
    float              noMotionThreshold = 0.004;
    
    std::deque<float>  FPS_30;
    
public:
    
    BreathRate(void);
    
    inline void clearRPM(){
        bufferVector.clear();
        rpmHistory.clear();
        
        bufferFeatures.clear();
        numFeatures = NUM_OF_FEATURES;
    }
    
    void    initRPM(GraftySystem& gsys);
    RStatus findBreathRate(size_t& BR);
    //RStatus findHeartRate(std::vector<std::deque<float>>& bufferFeatures, size_t& stepBin, float& responseValue);
    void    getRPM(std::vector<std::vector<cv::Point2f>>& nosePoints, GraftySystem& gsys, size_t& BPM);

    float getFPS();
    float getTrackingPercentage();
    
private:
    std::deque<std::chrono::time_point<std::chrono::high_resolution_clock>> clockVector;
};


#endif /* defined(__grafty_vp__grafty_core_breathrate__) */
