//
//  TopViewLayer.h
//  LiveVideoCapture
//
//  Created by MBP on 10/26/15.
//  Copyright © 2015 Grafty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KAProgressLabel.h"
#import "HeartLabel.h"

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@protocol TopViewLayerDelegate <NSObject>

@optional
-(void)circleProgressClicked:(id)sender;

@end

@interface TopViewLayer : UIView
@property (nonatomic, strong) KAProgressLabel   *circleProgressWithLabel;
@property (nonatomic, strong) UILabel           *infoLabel;
@property (nonatomic, strong) HeartLabel           *updateHeartLabel;
@property (nonatomic, strong) UILabel           *updateLabel;
@property (nonatomic, strong) UILabel           *bpmLabel;
@property (nonatomic, strong) UIButton          *closeButton;
@property (nonatomic, strong) UILabel           *heart;
@property (nonatomic, strong) UIButton          *startButton;
@property (nonatomic, strong) UILabel           *tapToStartLabel;
@property (nonatomic, strong) UIView            *middleCircleView;
//TopViewLayer Delegate declaration
@property (nonatomic, strong) id<TopViewLayerDelegate> delegate;


//used in landScape only
@property (nonatomic, strong) UILabel           *bPMResult;

-(id)initWithFrame:(CGRect)frame;
-(id)initWithFixedFrame:(CGRect)frame;
-(void)startBeatAnimation:(UILabel*)label;
-(void)stopBeatAnimation:(UILabel*)label;
-(void)closeAction:(id)sender;

-(IBAction)startButtonAction:(id)sender;
@end
