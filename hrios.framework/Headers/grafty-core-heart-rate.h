//
//  grafty-core-heartrate.h
//  grafty-hr
//
//  Created by Manish Mukherjee on 9/16/15.
//  Copyright (c) 2015 Grafty. All rights reserved.
//

#ifndef __grafty_vp__grafty_core_heartrate__
#define __grafty_vp__grafty_core_heartrate__

#include <stdio.h>
#include <chrono>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/video/tracking.hpp>
#include "grafty-core-utils.h"
#include "grafty-system-settings.h"
#include "grafty-core-buffer-vector.hpp"

#define BPM_VALID       1
#define BPM_NOT_VALID   !BPM_VALID

#define LOWEST_BPM      55.0f //40.0f
#define HIGHEST_BPM     200.0f

#define NUM_OF_FEATURES 3  //7

#define NUM_OF_SAMPLE_TO_AVERAGE 300 //90 //300

extern bool Camera;


class HeartRate {
    
    int                bufferVectorIndex   = 0;
    int                positiveBufferCount = 0;
    int                bufferVectorLength  = 0;
    int                filterDelay = 600; //600; // 224 for a 2 sec buffer length, and augmented 8 times.
    
    bool               bpm_inited = false;
    
    float              HzPerBin    = 0;
    float              frequencyBinIndexes[2];
    
    size_t             numFramesPerHeartRate;
    
    size_t             numHRCalculationsPerSec = 4;
    
    //thresholds
    float rejection_threshold = 10;
    float std_coefficient = 0.3; //0.8; //0.6; //0.3; //0.2;  //0.075; //0.2
    
    
    std::deque<size_t> bpmHistory;
    std::vector<size_t> bpmHistogram;
    
    std::vector<float> fAxis;
    HRBufferVector  bufferVector;
    
    std::vector<std::deque<float>> bufferFeatures;
    
    std::vector<std::deque<float>> absFreqVectorQueue;
    
    size_t numFeatures =NUM_OF_FEATURES;
//    std::vector<float> variance;
    std::vector<size_t> sorted_variance_idx;
    
    size_t numOfSampleToAverage = NUM_OF_SAMPLE_TO_AVERAGE;

    
    
    float              NFFT         = 0;
    float              bpm2Hz[2]    = { LOWEST_BPM/60.0f, HIGHEST_BPM/60.0f }; // Define the bandpass frequencies
    float              noMotionThreshold = 0.004;
    
    std::deque<float>  FPS_30;
    
public:
    
    HeartRate(void);
    
    inline void clearBpm(){
        bufferVector.clear();
        clockVector.clear();
        bpmHistory.clear();
        bpmHistogram.clear();
        
        bufferFeatures.clear();
        numFeatures = NUM_OF_FEATURES;
    }
    
    void    initBpm(GraftySystem& gsys);
    RStatus findHeartRate(HRBufferVector& bufferVector, size_t& HR);
    //RStatus findHeartRate(std::vector<std::deque<float>>& bufferFeatures, size_t& stepBin, float& responseValue);
    void    getBpm(std::vector<std::vector<cv::Point2f>>& nosePoints, GraftySystem& gsys, size_t& BPM);

    float getFPS();
    float getTrackingPercentage();
    
private:
    std::deque<std::chrono::time_point<std::chrono::high_resolution_clock>> clockVector;
};


#endif /* defined(__grafty_vp__grafty_core_heartrate__) */
