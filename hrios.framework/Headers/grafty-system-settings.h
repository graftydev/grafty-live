//
//  grafty-system-settings.h
//  grafty-hr
//
//  Created by Manish Mukherjee on 7/4/15.
//  Copyright (c) 2015 Grafty. All rights reserved.
//

#ifndef __grafty_vp__grafty_system_settings__
#define __grafty_vp__grafty_system_settings__

#include <stdio.h>
#include <math.h>



#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/video/tracking.hpp>
#include "grafty-core-utils.h"

enum GraftyImageType
{
    GRAFTY_BGRA = 1,
    GRAFTY_BGR = 2,
    GRAFTY_Y_CB_CR = 3
};
class GraftySystem {

private:
    float frameHeight;
    float frameWidth;
    cv::Ptr<cv::CLAHE> clahe;
    
public:
    GraftyImageType imageType;
    float   frameRate;
    size_t  frameCount;
    
    cv::Mat nFrame;
    void *sampleBuffer;
    
    
    cv::Mat pRedFrame;
    cv::Mat nRedFrame;
    
    cv::Mat pGreenFrame;
    cv::Mat nGreenFrame;
    
    PState programState;
    
    //added another programStage for good featurs tracker
    PState programState_gf;

    cv::CascadeClassifier     face_cascade;
    cv::CascadeClassifier     nose_cascade;

    GraftySystem ();
    void setFrameRate    (float f);
    float getFrameRate (void);
                        
    void     setCurrentFrame(cv::Mat& frame);
    size_t   getFrameCount(void);
    cv::Mat& getCurrentFrame();
    
    void    swapFrames(void);
    void    saveCurrentFrame(void);

    
    size_t  getFrameWidth(void);
    size_t  getFrameHeight(void);
    
    void setProgramState (PState ps);
    PState getProgramState (void);

    void setProgramState_gf (PState ps);
    PState getProgramState_gf (void);
    
    bool loadFaceCascade(std::string& s);
    bool loadNoseCascade(std::string& s);
    inline cv::Ptr<cv::CLAHE> getClahe() { return (this->clahe); }
    
    
};

#endif /* defined(__grafty_vp__grafty_system_settings__) */
