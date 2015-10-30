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
        w=320;
    }
    self.circleProgressWithLabel = [[KAProgressLabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width-w, self.frame.size.width-w)];
    
    self.circleProgressWithLabel.center = centerAdjusted;
    
    self.circleProgressWithLabel.fillColor = [UIColor clearColor];
    self.circleProgressWithLabel.trackColor = [UIColor grayColor];
    self.circleProgressWithLabel.progressColor = [UIColor greenColor];
    
    self.circleProgressWithLabel.trackWidth = 15.0;         // Defaults to 5.0
    self.circleProgressWithLabel.progressWidth = 15.0;        // Defaults to 5.0
    self.circleProgressWithLabel.roundedCornersWidth = 0; // Defaults to 0
    self.circleProgressWithLabel.progress = 0.0;
    self.circleProgressWithLabel.startLabel.text = @"test";
    self.circleProgressWithLabel.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270*2));
    
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
            __self.infoLabel.text = @"";//[NSString stringWithFormat:@"TRACKING %.0f%%", (label.progress * 100)];
        }
        
    };
    
    
    //set infoLabel
    //calculating y possition based on circle width
    float yToCircle =(self.circleProgressWithLabel.frame.origin.y + self.circleProgressWithLabel.frame.size.width);
    float y= yToCircle + (self.frame.size.height - yToCircle)/2;
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,y, self.frame.size.width, 40)];
    self.infoLabel.text = @"POSITION FACE IN THE CIRCLE"; //default value
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    self.infoLabel.font = [TopViewLayerSettings labelFont];
    self.infoLabel.textColor =[TopViewLayerSettings labelColor];
    self.infoLabel.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270*2));
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
     self.updateHeartLabel.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270*2));
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
    self.closeButton.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270*2));
    self.closeButton.layer.borderWidth = 0.0F;
    
    [self addSubview:self.closeButton];
}



@end
