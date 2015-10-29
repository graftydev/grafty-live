//
//  grafty-core-pedometry.h
//  grafty-hr
//
//  Created by Manish Mukherjee on 6/10/15.
//  Copyright (c) 2015 Grafty. All rights reserved.
//

#ifndef __grafty_vp__grafty_core_pedometry__
#define __grafty_vp__grafty_core_pedometry__

#include <stdio.h>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/video/tracking.hpp>
#include "grafty-core-utils.h"
#include "grafty-system-settings.h"

#define SPM_VALID       1
#define SPM_NOT_VALID   !SPM_VALID

#define LOWEST_SPM      30.0f
#define HIGHEST_SPM     300.0f



class Pedometer {
    
    int                bufferVectorIndex   = 0;
    int                positiveBufferCount = 0;
    int                bufferVectorLength  = 0;
    
    bool               spm_inited = false;
    
    float              HzPerBin    = 0;
    float              frequencyBinIndexes[2];
    std::deque<size_t> spmHistory;

    std::vector<float> fAxis;
    std::deque<float>  bufferVectorX, bufferVectorY;
    
    
    float              NFFT         = 0;
    float              bpm2Hz[2]    = { LOWEST_SPM/60.0f, HIGHEST_SPM/60.0f }; // Define the bandpass frequencies
    float              noMotionThreshold = 0.004;
    
public:
    Pedometer(void);
    void    initSpm(GraftySystem& gsys);
    RStatus findStepBinX(std::deque<float>& bufferVector, size_t& stepBin, float& responseValue, float& motionStrength);
    RStatus findStepBinY(std::deque<float>& bufferVector, size_t& stepBin, float& responseValue, float& motionStrength);
    void    getSpm(std::vector<cv::Point2f>& nosePoints, GraftySystem& gsys, size_t& spm, float& motionStrengthX, float& motionStrengthY );
};


#endif /* defined(__grafty_vp__grafty_core_pedometry__) */
