//
//  grafty-trigger-vp.h
//  grafty-hr
//
//  Created by Manish Mukherjee on 7/5/15.
//  Copyright (c) 2015 Grafty. All rights reserved.
//

#ifndef __grafty_vp__grafty_trigger_vp__
#define __grafty_vp__grafty_trigger_vp__

#include <stdio.h>
#include "grafty-face-class.h"
#include "grafty-system-settings.h"


#define  TRACK_MIN_POINT_COUNT          50
#define  TRACK_MAX_POINT_COUNT          100



int trigger_hr(GraftySystem& gsys, GraftyFaceList& faces, dlib::shape_predictor& pose_model);
//int trigger_hr_gf(GraftySystem& gsys_gf, GraftyFaceList& faces_gf, dlib::shape_predictor& pose_model);


#endif /* defined(__grafty_vp__grafty_trigger_vp__) */
