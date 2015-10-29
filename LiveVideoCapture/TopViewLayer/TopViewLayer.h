//
//  TopViewLayer.h
//  LiveVideoCapture
//
//  Created by MBP on 10/26/15.
//  Copyright © 2015 Grafty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KAProgressLabel.h"

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface TopViewLayer : UIView
@property (nonatomic, strong) KAProgressLabel   *circleProgressWithLabel;
@property (nonatomic, strong) UILabel           *infoLabel;
@property (nonatomic, strong) UILabel           *updateLabel;
@property (nonatomic, strong) UILabel           *bpmLabel;
@property (nonatomic, strong) UIButton          *closeButton;
@property (nonatomic, strong) UILabel           *heart;

//used in landScape only
@property (nonatomic, strong) UILabel           *bPMResult;

-(id)initWithFrame:(CGRect)frame;
-(void)startBeatAnimation:(UILabel*)label;
-(void)stopBeatAnimation:(UILabel*)label;
-(void)closeAction:(id)sender;
@end
