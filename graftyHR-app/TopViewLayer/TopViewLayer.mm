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
    CAShapeLayer *fillLayer ;
}
@synthesize delegate=_delegate, tapToStartLabel = _tapToStartLabel;
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(id)init{
    self  = [super init];
    if(self)
    {
        self.frame=[[UIScreen mainScreen] bounds];
        
        
        [self setupView];
        self.alpha = 1;
        

    }
    return self;
}
-(id)initWithFrame:(CGRect)frame
{
    self  = [super initWithFrame:frame];
    return self;
}

#pragma Rotation View
-(void)setupView
{
    padingFromCenter = -40;
    
    centerAdjusted = CGPointMake(self.center.x, self.center.y-40);
    float w = 25;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        w=100;
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
            //__self.infoLabel.text = @"Estimating..";//[NSString stringWithFormat:@"TRACKING %.0f%%", (label.progress * 100)];
        }
        
    };
    
    
    //set infoLabel
    //calculating y possition based on circle width
    float y= self.circleProgressWithLabel.frame.origin.y/2 ;
    if(y<0)
        y=0;
    
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,y, self.frame.size.width, 40)];
    self.infoLabel.text = @"Position face in the circle"; //default value
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    self.infoLabel.font = [TopViewLayerSettings labelFont];
    self.infoLabel.textColor =[TopViewLayerSettings labelColor];
    //add to view
    [self addSubview:self.infoLabel];
    
    //set updateLabel
    //calculating y possition based on circle width
    y= centerAdjusted.y + self.circleProgressWithLabel.frame.size.height/2.0 +5 ;
    if(y>self.frame.size.height)
        y= self.frame.size.height- 120;
    self.updateHeartLabel = [[HeartLabel alloc] initWithFrame:CGRectMake(0, y, self.frame.size.width, 120)];
    self.updateHeartLabel.label.text = @"...";//default value
    self.updateHeartLabel.label.textAlignment = NSTextAlignmentCenter;
    self.updateHeartLabel.label.font = [TopViewLayerSettings labelFontWithSize:30.0F];
    self.updateHeartLabel.label.numberOfLines =2;
    self.updateHeartLabel.label.textColor =[TopViewLayerSettings labelColor];
    self.updateHeartLabel.heart.font=[TopViewLayerSettings labelFontWithSize:30.0F];
    //add to view
    [self addSubview:self.updateHeartLabel];
    
    //add close button
    CGRect bounds = [[UIScreen mainScreen] bounds];
    y=bounds.size.height -  self.updateHeartLabel.frame.origin.y + self.updateHeartLabel.frame.size.height;
    y= y/2.0 -160;
    
      self.closeButton =[[UIButton alloc] initWithFrame:CGRectMake(bounds.size.width/4.0, y/2.0 +self.updateHeartLabel.frame.origin.y + self.updateHeartLabel.frame.size.height , bounds.size.width/2.0 , 40 )];
    
    [self.closeButton setTitle:@"CLOSE" forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.closeButton setBackgroundColor:[UIColor redColor]];
    self.closeButton.layer.cornerRadius = 5.0F;
    self.closeButton.layer.borderColor = [[TopViewLayerSettings labelColor] CGColor];
    self.closeButton.layer.borderWidth = 0.0F;
    
    [self addSubview:self.closeButton];
    
    
    //tap me to start
    //Adding tapToStartlabel
    self.middleCircleView =[[UIView alloc] initWithFrame:CGRectMake(self.circleProgressWithLabel.frame.origin.x, self.circleProgressWithLabel.center.y, self.circleProgressWithLabel.frame.size.width-17, self.circleProgressWithLabel.frame.size.width-15)];
    self.middleCircleView.backgroundColor = [UIColor clearColor];
    self.middleCircleView.center = self.circleProgressWithLabel.center;
    
    
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
    self.tapToStartLabel.frame = CGRectMake(0,self.middleCircleView.frame.size.height/2.0 - 35/2.0, self.middleCircleView.frame.size.width, 35);
    
    self.tapToStartLabel.backgroundColor = [UIColor clearColor];
    self.tapToStartLabel.alpha = 0.8;
    self.tapToStartLabel.textAlignment  = NSTextAlignmentCenter;
    self.tapToStartLabel.font = [TopViewLayerSettings labelFont];
    self.tapToStartLabel.textColor = [UIColor whiteColor];
    self.tapToStartLabel.layer.cornerRadius = 5.0;
    self.tapToStartLabel.text=@"Tap to start...";
    [self.middleCircleView addSubview:self.tapToStartLabel];
    [self bringSubviewToFront:self.middleCircleView];
    
    
    self.middleCircleView.layer.cornerRadius = self.middleCircleView.frame.size.width/2.0;
    self.middleCircleView.layer.masksToBounds = YES;
    self.middleCircleView.clipsToBounds = YES;
    
    //Adding tap gesture to the circle
     tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(circleTapAction:)];
    [tap setNumberOfTapsRequired:1];
    [self.middleCircleView addGestureRecognizer:tap];
    
}

#pragma -mark Actions
-(void)startBeatAnimation:(UILabel*)label{
    
    CABasicAnimation *theAnimation;
    theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    theAnimation.duration=0.7;
    theAnimation.repeatCount=HUGE_VALF;
    theAnimation.autoreverses=YES;
    theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
    theAnimation.toValue=[NSNumber numberWithFloat:0.7];
    theAnimation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [label.layer addAnimation:theAnimation forKey:@"animateOpacity"];
}
-(void)stopBeatAnimation:(UILabel*)label
{
    [label.layer removeAllAnimations];
}
-(void)circleTapAction:(id)sender
{
    if(_delegate)
        [_delegate circleProgressClicked:sender];
}
-(IBAction)startButtonAction:(id)sender{
    
}
-(void)closeAction:(id)sender
{
    exit(0);
}


@end
