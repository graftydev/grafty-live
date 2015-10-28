//
//  TopViewLayer.m
//  LiveVideoCapture
//
//  Created by MBP on 10/26/15.
//  Copyright © 2015 Grafty. All rights reserved.
//

#import "TopViewLayer.h"
#import <QuartzCore/QuartzCore.h>
#import "TopViewLayerSettings.h"

@implementation TopViewLayer
{
    float padingFromCenter;
    CGPoint centerAdjusted;
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
        
        padingFromCenter = -40;
        
        centerAdjusted = CGPointMake(self.center.x, self.center.y-40);
        
        self.circleProgressWithLabel = [[KAProgressLabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width-20, self.frame.size.width-20)];
        
        self.circleProgressWithLabel.center = centerAdjusted;
        
        self.circleProgressWithLabel.fillColor = [UIColor clearColor];
        self.circleProgressWithLabel.trackColor = [UIColor grayColor];
        self.circleProgressWithLabel.progressColor = [UIColor greenColor];
        
        self.circleProgressWithLabel.trackWidth = 15.0;         // Defaults to 5.0
        self.circleProgressWithLabel.progressWidth = 15.0;        // Defaults to 5.0
        self.circleProgressWithLabel.roundedCornersWidth = 0; // Defaults to 0
        self.circleProgressWithLabel.progress = 0.0;
        self.circleProgressWithLabel.startLabel.text = @"test";
        //Adding Mask that will clear the inside color of the Circle.
        int radius = self.circleProgressWithLabel.frame.size.width;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height) cornerRadius:0];
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(self.circleProgressWithLabel.frame.origin.x, self.circleProgressWithLabel.frame.origin.y, radius, radius) cornerRadius:radius];
        [path appendPath:circlePath];
        [path setUsesEvenOddFillRule:YES];
        
        CAShapeLayer *fillLayer = [CAShapeLayer layer];
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
        float y= centerAdjusted.y - self.circleProgressWithLabel.frame.size.height/2.0 -35.0 ;
            if(y<0)
                y=0;
        
        self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,y, self.frame.size.width, 40)];
        self.infoLabel.text = @"POSITION FACE IN THE CIRCLE"; //default value
        self.infoLabel.textAlignment = NSTextAlignmentCenter;
        self.infoLabel.font = [TopViewLayerSettings labelFont];
        self.infoLabel.textColor =[TopViewLayerSettings labelColor];
        //add to view
        [self addSubview:self.infoLabel];
        
        //set updateLabel
        //calculating y possition based on circle width
        y= centerAdjusted.y + self.circleProgressWithLabel.frame.size.height/2.0 +5 ;
        if(y>self.frame.size.height)
            y= self.frame.size.height- 80;
        self.updateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, self.frame.size.width, 80)];
        self.updateLabel.text = @"DETECTING...";//default value
        self.updateLabel.textAlignment = NSTextAlignmentCenter;
        self.updateLabel.font = [TopViewLayerSettings labelFontWithSize:37.0F];
        self.updateLabel.numberOfLines =2;
        self.updateLabel.textColor =[TopViewLayerSettings labelColor];
       
        
        
        //add to view
        [self addSubview:self.updateLabel];
        
        //add close button
        CGRect bounds = [[UIScreen mainScreen] bounds];
        y=bounds.size.height -  self.updateLabel.frame.origin.y + self.updateLabel.frame.size.height;
        y= y/2.0 -120;
        
        UIButton * closeButton =[[UIButton alloc] initWithFrame:CGRectMake(bounds.size.width/4.0, y/2.0 +self.updateLabel.frame.origin.y + self.updateLabel.frame.size.height , bounds.size.width/2.0 , 40 )];
        
        [closeButton setTitle:@"CLOSE" forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
        [closeButton setBackgroundColor:[UIColor redColor]];
        closeButton.layer.cornerRadius = 5.0F;
        closeButton.layer.borderColor = [[TopViewLayerSettings labelColor] CGColor];
        closeButton.layer.borderWidth = 1.0F;
        
        
        
        [self addSubview:closeButton];
        
        self.alpha = 1;
        //[self startBeatAnimation];
        
    }
    return self;
}

-(void)startBeatAnimation{
    
    CABasicAnimation *theAnimation;
    theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    theAnimation.duration=0.7;
    theAnimation.repeatCount=HUGE_VALF;
    theAnimation.autoreverses=YES;
    theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
    theAnimation.toValue=[NSNumber numberWithFloat:0.7];
    theAnimation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [self.updateLabel.layer addAnimation:theAnimation forKey:@"animateOpacity"];
}

-(void)stopBeatAnimation
{
    [self.updateLabel.layer removeAllAnimations];
}

-(void)closeAction:(id)sender
{
    exit(0);
}
@end
