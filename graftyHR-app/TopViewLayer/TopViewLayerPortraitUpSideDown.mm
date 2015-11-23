//
//  TopViewLayer.m
//  LiveVideoCapture
//
//  Created by MBP on 10/26/15.
//  Copyright © 2015 Grafty. All rights reserved.
//

#import "TopViewLayerPortraitUpSideDown.h"
#import <QuartzCore/QuartzCore.h>
#import "TopViewLayerSettings.h"

@implementation TopViewLayerPortraitUpSideDown
{
    float padingFromCenter;
    CGPoint centerAdjusted;
    CAShapeLayer *fillLayer ;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(id)initWithFrame:(CGRect)frame
{
    self  = [super initWithFrame:frame];
    if(self)
    {
        
        [self setupView];
        if(self.heart != nil)
            [self startBeatAnimation:self.heart];
    }
    return self;
}

#pragma Rotation View
-(void)setupView
{
    padingFromCenter = 60;
    
    centerAdjusted = CGPointMake(self.center.x, self.center.y+padingFromCenter);
    float w = 25;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        w=400;
    }
    self.circleProgressWithLabel = [[KAProgressLabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width-w, self.frame.size.width-w)];
    
    self.circleProgressWithLabel.center = centerAdjusted;
    
    self.circleProgressWithLabel.fillColor = [UIColor clearColor];
    self.circleProgressWithLabel.trackColor = [UIColor orangeColor];
    self.circleProgressWithLabel.progressColor = [UIColor greenColor];
    
    self.circleProgressWithLabel.trackWidth = 15.0;         // Defaults to 5.0
    self.circleProgressWithLabel.progressWidth = 15.0;        // Defaults to 5.0
    self.circleProgressWithLabel.roundedCornersWidth = 0; // Defaults to 0
    self.circleProgressWithLabel.progress = 0.0;
    self.circleProgressWithLabel.startLabel.text = @"test";
    //self.circleProgressWithLabel.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270*2));
    
    
    //Adding tap gesture to the circle
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(circleTapAction:)];
    [tap setNumberOfTapsRequired:1];
    [self.circleProgressWithLabel addGestureRecognizer:tap];
    
    //Adding Mask that will clear the inside color of the Circle.
    int radius = self.circleProgressWithLabel.frame.size.width;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height) cornerRadius:0];
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(self.circleProgressWithLabel.frame.origin.x, self.circleProgressWithLabel.frame.origin.y, radius, radius) cornerRadius:radius];
    [path appendPath:circlePath];
    [path setUsesEvenOddFillRule:YES];
    
    fillLayer = [CAShapeLayer layer];
    fillLayer.path = path.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.fillColor = [TopViewLayerSettings backGroundColor].CGColor;
    fillLayer.opacity = 1;
    [self.layer addSublayer:fillLayer];
    
    
    
    self.backgroundColor    =[UIColor clearColor];
    
    //Add Progress Circle to the view.
    [self addSubview:self.circleProgressWithLabel];
    
    __weak TopViewLayer * __self=self;
    self.circleProgressWithLabel.labelVCBlock = ^(KAProgressLabel *label) {
        label.text = @"";//[NSString stringWithFormat:@"TRACKING %.0f%%", (label.progress * 100)];
        if( label.progress>0)
        {
            __self.infoLabel.text = @"Estimating..";//[NSString stringWithFormat:@"TRACKING %.0f%%", (label.progress * 100)];
        }
        
    };
    
    
    //set infoLabel
    //calculating y possition based on circle width
    float yToCircle =(self.circleProgressWithLabel.frame.origin.y + self.circleProgressWithLabel.frame.size.width);
    float y= yToCircle + (self.frame.size.height - yToCircle)/2;
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,y, self.frame.size.width, 40)];
    self.infoLabel.text = @"Position face in the circle"; //default value
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    self.infoLabel.font = [TopViewLayerSettings labelFont];
    self.infoLabel.textColor =[TopViewLayerSettings labelColor];
    //self.infoLabel.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270*2));
    //add to view
    [self addSubview:self.infoLabel];
    
    //set updateLabel
    //calculating y possition based on circle width
    y= self.circleProgressWithLabel.frame.origin.y - 100;
    self.updateHeartLabel = [[HeartLabel alloc] initWithFrame:CGRectMake(0, y, self.frame.size.width, 120)];
    self.updateHeartLabel.label.text = @"...";//default value
    self.updateHeartLabel.label.textAlignment = NSTextAlignmentCenter;
    self.updateHeartLabel.label.font = [TopViewLayerSettings labelFontWithSize:30.0F];
    self.updateHeartLabel.label.numberOfLines =2;
    self.updateHeartLabel.label.textColor =[TopViewLayerSettings labelColor];
     //self.updateHeartLabel.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270*2));
    self.updateHeartLabel.heart.font=[TopViewLayerSettings labelFontWithSize:30.0F];
    //add to view
    [self addSubview:self.updateHeartLabel];
    
    //add close button
    CGRect bounds = [[UIScreen mainScreen] bounds];
    y=self.circleProgressWithLabel.frame.origin.y - 100 - 60 ;
    
    self.closeButton =[[UIButton alloc] initWithFrame:CGRectMake(bounds.size.width/4.0, y  , bounds.size.width/2.0 , 40 )];
    
    [self.closeButton setTitle:@"CLOSE" forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.closeButton setBackgroundColor:[UIColor redColor]];
    self.closeButton.layer.cornerRadius = 5.0F;
    self.closeButton.layer.borderColor = [[TopViewLayerSettings labelColor] CGColor];
   // self.closeButton.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270*2));
    self.closeButton.layer.borderWidth = 0.0F;
    
    [self addSubview:self.closeButton];
    /*
    //Adding tapToStartlabel
    self.tapToStartLabel = [[UILabel alloc] init];
    self.tapToStartLabel.frame = CGRectMake(self.circleProgressWithLabel.frame.origin.x+30, self.circleProgressWithLabel.center.y-35/2, self.circleProgressWithLabel.frame.size.width-60, 35);
    self.tapToStartLabel.backgroundColor = [UIColor blackColor];
    self.tapToStartLabel.alpha = 0.8;
    self.tapToStartLabel.textAlignment  = NSTextAlignmentCenter;
    self.tapToStartLabel.font = [TopViewLayerSettings labelFont];
    self.tapToStartLabel.textColor = [UIColor whiteColor];
    self.tapToStartLabel.layer.cornerRadius = 5.0;
    self.tapToStartLabel.text=@"Tap me to start...";
    self.tapToStartLabel.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270*2));
    [self addSubview:self.tapToStartLabel];
    [self bringSubviewToFront:self.tapToStartLabel];
     */
    
    //tap me to start
    //Adding tapToStartlabel
    self.middleCircleView =[[UIView alloc] initWithFrame:CGRectMake(self.circleProgressWithLabel.frame.origin.x, self.circleProgressWithLabel.center.y, self.circleProgressWithLabel.frame.size.width-17, self.circleProgressWithLabel.frame.size.width-15)];
    self.middleCircleView.backgroundColor = [UIColor clearColor];
    self.middleCircleView.center = self.circleProgressWithLabel.center;
    self.middleCircleView.layer.cornerRadius = self.middleCircleView.frame.size.width/2.0;
    self.middleCircleView.layer.masksToBounds = YES;
    self.middleCircleView.clipsToBounds = YES;
    
    // Create the colors
    UIColor *topColor = [UIColor clearColor];
    UIColor *bottomColor = [UIColor clearColor];
    
    // Create the gradient
    CAGradientLayer *theViewGradient = [CAGradientLayer layer];
    theViewGradient.colors = [NSArray arrayWithObjects: (id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    theViewGradient.frame =  self.middleCircleView.bounds;
    
    //Add gradient to view
    [ self.middleCircleView.layer insertSublayer:theViewGradient atIndex:0];
    
    [self addSubview:self.middleCircleView];
    self.tapToStartLabel = [[UILabel alloc] init];
    self.tapToStartLabel.frame =CGRectMake(0,self.middleCircleView.frame.size.height/2.0 - 35/2.0, self.middleCircleView.frame.size.width, 35);
    
    self.tapToStartLabel.backgroundColor = [UIColor clearColor];
    self.tapToStartLabel.alpha = 0.8;
    self.tapToStartLabel.textAlignment  = NSTextAlignmentCenter;
    self.tapToStartLabel.font = [TopViewLayerSettings labelFont];
    self.tapToStartLabel.textColor = [UIColor whiteColor];
    self.tapToStartLabel.layer.cornerRadius = 5.0;
    self.tapToStartLabel.text=@"Tap me to start...";
    //self.middleCircleView.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270*2));
    [self.middleCircleView addSubview:self.tapToStartLabel];
    [self bringSubviewToFront:self.middleCircleView];
    
    //Adding tap gesture to the circle
    tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(circleTapAction:)];
    [tap setNumberOfTapsRequired:1];
    [self.middleCircleView addGestureRecognizer:tap];
}



@end
