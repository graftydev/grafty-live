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
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/video/tracking.hpp>
#include "grafty-core-utils.h"
#include "grafty-system-settings.h"

#define BPM_VALID       1
#define BPM_NOT_VALID   !BPM_VALID

#define LOWEST_BPM      55.0f //40.0f
#define HIGHEST_BPM     200.0f


#define NUM_OF_FEATURES 3  //7

#define NUM_OF_FFT_TO_AVERAGE 300

class HeartRate {
    
    int                bufferVectorIndex   = 0;
    int                positiveBufferCount = 0;
    int                bufferVectorLength  = 0;
    int                filterDelay = 224; // 224 for a 2 sec buffer length, and augmented 8 times.
    
    bool               fft_inited = false;
    
    float              HzPerBin    = 0;
    float              frequencyBinIndexes[2];
    std::deque<size_t> bpmHistory;

    std::vector<float> fAxis;
    std::deque<float>  bufferVector;
    
    std::vector<std::deque<float>> bufferFeatures;
    
    std::vector<std::deque<float>> absFreqVectorQueue;
    
    size_t numFeatures =NUM_OF_FEATURES;
//    std::vector<float> variance;
    std::vector<size_t> sorted_variance_idx;
    
    size_t numOfFFTToAverage = NUM_OF_FFT_TO_AVERAGE;

    
    
    float              NFFT         = 0;
    float              bpm2Hz[2]    = { LOWEST_BPM/60.0f, HIGHEST_BPM/60.0f }; // Define the bandpass frequencies
    float              noMotionThreshold = 0.004;
    
public:
    
    HeartRate(void);
    
    inline void clearBpm(){
        bufferVector.clear();
        bpmHistory.clear();
        
        bufferFeatures.clear();
        numFeatures = NUM_OF_FEATURES;
    }
    
    void    initBpm(GraftySystem& gsys);
    RStatus findHeartRate(std::deque<float>& bufferVector, size_t& stepBin, float& responseValue);
    RStatus findHeartRate(std::vector<std::deque<float>>& bufferFeatures, size_t& stepBin, float& responseValue);
    void    getBpm(std::vector<std::vector<cv::Point2f>>& nosePoints, GraftySystem& gsys, size_t& BPM);
};


#endif /* defined(__grafty_vp__grafty_core_heartrate__) */
