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


#define GRAFTY_DISPLAY_68            false // true
#define  GRAFTY_DEBUG                false //true
#define GRAFTY_DISPLAY_RAW           false
#define GRAFTY_DISPLAY_AUG           false //true
#define GRAFTY_DISPLAY_FILTERED      false

#define TIME_BUFFER_INTERVAL   5 //5

static bool Camera = true;

extern void create_bounding_box_from_points(std::vector<cv::Point2f>& in, cv::Rect_<float>& out);
//extern void cleansePoints(const std::vector<cv::Point2f>& points, std::vector<cv::Point2f> filtered);
float farFromCentroid(cv::Point2f& p, cv::Point2f& centroid, float radius);




//size_t hrContourIdx [] = {31, 35, 45, 36};  //outer eye corners
static size_t hrContourIdx [] = {31, 35, 42, 39};    //inner eye corners
static size_t noseBboxIdx [] = {31, 35, 30};         //nose corners
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

enum PState {
    DETECT      =1,
    TRACK_UPDATE = 2,
    TRACK_MAINTAIN = 3
};
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

float averageIntensityOfPolygonContour(cv::Mat nFrame, cv::Mat Img,std::vector<cv::Point2f>& polygonContour);
float averageIntensityOfPolygonContour(cv::Mat Img, std::vector< std::vector<cv::Point2f>> polygonContours);

float averageIntensityOfPoints(cv::Mat Img, std::vector<cv::Point2f> points);

float averageIntensityOfConvexHullPolygonContour(cv::Mat Img, std::vector<cv::Point2f> polygonContour);

std::vector<float> averageIntensityOfNRegions(cv::Mat Img, std::vector<cv::Point2f> polygonContour, size_t N);

float var(std::vector<float> &a);
float var(std::deque<float> &a);

//template <typename T>
std::vector<size_t> sort_idx(const std::vector<float> &v);


bool writeVectorEveryFrame(std::string fileName, std::vector<float> x);
bool writeDequeEveryFrame(std::string fileName, std::deque<float> x);
bool writeValueEveryFrame(std::string fileName, float x);

float median(std::vector<size_t>& scores);
float median(std::deque<size_t>& scores);
float interpolateCVMat(cv::Mat Img, cv::Point2f p);
std::vector<cv::Point2f> goodFeaturesAroundPoints(cv::Mat& Img, std::vector<cv::Point2f>& Points, float distanceThreshold);
bool filter(const std::vector<float>& b, const std::vector<float>& a, std::vector<float>& X, std::vector<float> & Y);
std::vector<float> augmentSignalForFFT(std::vector<float>& S, size_t filterDelay, size_t NFFT);
float mean(std::deque<float> X);
float mean(std::vector<float> X);
#endif /* defined(__grafty_vp__grafty_core_utils__) */
