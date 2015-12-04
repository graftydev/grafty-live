//
//  grafty-core-utils.h
//  grafty-hr
//
//  Created by Manish Mukherjee on 6/2/15.
//  Copyright (c) 2015 Grafty. All rights reserved.
//

#ifndef __grafty_vp__grafty_core_utils__
#define __grafty_vp__grafty_core_utils__

#include <stdio.h>
#include <math.h>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/video/tracking.hpp>


#define GRAFTY_DISPLAY_68            false //true //true
#define  GRAFTY_DEBUG                false //true

#define GRAFTY_DISPLAY_BPM_RAW           false //true //false
#define GRAFTY_DISPLAY_BPM_AUG           false //true
#define GRAFTY_DISPLAY_BPM_FILTERED      false //true //false

#define GRAFTY_DISPLAY_FFT               false //true

#define GRAFTY_DISPLAY_RPM_RAW           false //true
#define GRAFTY_DISPLAY_RPM_AUG           false //true
#define GRAFTY_DISPLAY_RPM_FILTERED      false //true


#define SPM_BUFFER_INTERVAL   5 //5
#define BPM_BUFFER_INTERVAL   10 //5
#define RPM_BUFFER_INTERVAL   20 //5

#define MAC_Y_CB_CR     1


static bool Camera;

extern void create_bounding_box_from_points(std::vector<cv::Point2f>& in, cv::Rect_<float>& out);
//extern void cleansePoints(const std::vector<cv::Point2f>& points, std::vector<cv::Point2f> filtered);
float farFromCentroid(cv::Point2f& p, cv::Point2f& centroid, float radius);




//static size_t hrContourIdx [] = {31, 35, 45, 36};  //outer eye corners
static size_t hrContourIdx [] = {31, 35, 42, 39};    //inner eye corners
static size_t noseBboxIdx []  = {31, 35, 30};         //nose corners
//static size_t hrContourIdx [] = {31, 32, 33, 34, 35, 35, 28};    //nose corners
//static size_t hrContourIdx [] = {60, 59, 58, 57, 56, 55, 64, 63, 62, 61};    //lower lip
//static size_t hrContourIdx [] = {36, 41, 40, 39, 27, 42, 47, 46, 45, 35, 34, 33, 32, 31};
//static size_t hrContourIdx [] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17};


static bool  FIND_GOOD_FEATURES = false;
static float DLIB_TRACK_NOSE_POINT_THRESHOLD = 5;

template <typename T = double>
std::vector<T> linspace(T a, T b, size_t N) {
    T h = (b - a) / static_cast<T>(N-1);
    std::vector<T> xs(N);
    typename std::vector<T>::iterator x;
    T val;
    for (x = xs.begin(), val = a; x != xs.end(); ++x, val += h)
        *x = val;
    return xs;
}


extern int nextpow2(int x);

enum RStatus {
    BAD = -1,
    OK  =  0,
    NOK = 1
};

template <typename T> int sgn(T val) {
    return (T(0) < val) - (val < T(0));
}

inline int isLeft(cv::Point2f a, cv::Point2f b, cv::Point2f c)
{
    return sgn(((b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x)));
    
}

bool quadrilateralInteriorTest( std::vector<cv::Point2f>& vertexPoints, cv::Point2f& testPoint );

float averageIntensityOfPolygonContour(const cv::Mat& Img,std::vector<cv::Point2f>& polygonContour);
cv::Vec3f averageRgbOfPolygonContour(const cv::Mat& nFrame, const cv::Mat& nGreenFrame, std::vector<cv::Point2f>& polygonContour);

float averageIntensityOfPoints(cv::Mat Img, std::vector<cv::Point2f> points);

float averageIntensityOfConvexHullPolygonContour(cv::Mat Img,  std::vector<cv::Point2f> polygonContour);

std::vector<float> averageIntensityOfNRegions(cv::Mat Img, std::vector<cv::Point2f> polygonContour, size_t N);

float zeroMeanVar(const std::vector<float> &a);
float var(const std::deque<float> &a);
float var(const std::vector<float> &a);

//template <typename T>
std::vector<size_t> sort_idx(const std::vector<float> &v);


bool writeVectorEveryFrame(std::string fileName, std::vector<float> x);
bool writeDequeEveryFrame(std::string fileName, std::deque<float> x);
bool writeValueEveryFrame(std::string fileName, float x);

float median(std::vector<float> scores);
float median(std::vector<size_t> scores);
float median(std::deque<size_t> scores);
float interpolateCVMat(cv::Mat Img, cv::Point2f p);
std::vector<cv::Point2f> goodFeaturesAroundPoints(cv::Mat& Img, std::vector<cv::Point2f>& Points, float distanceThreshold);
bool filter(const std::vector<float>& b, const std::vector<float>& a, std::vector<float>& X, std::vector<float> & Y);
std::vector<float> augmentSignal(std::vector<float>& S, size_t filterDelay, size_t NFFT);
float mean(std::deque<float> X);
float mean(std::vector<float> X);
void print(std::deque<size_t> scores);
int  peakCount(std::vector<float>& inputData);
void medianSmoothing(std::vector<float>& inputData, std::vector<float>& outputData);
void  butterworthBandpassFilter(std::vector<float>& inputData, std::vector<float>& outputData);
void luxOfContour(const cv::Mat& nFrame,
                   const cv::Mat& nGreenFrame,
                   std::vector<cv::Point2f>& polygonContour,
                   float& outLux,
                  float& outTemp);
#endif /* defined(__grafty_vp__grafty_core_utils__) */
