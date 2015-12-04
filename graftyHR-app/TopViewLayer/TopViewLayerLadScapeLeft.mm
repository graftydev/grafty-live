//
//  TopViewLayer.m
//  LiveVideoCapture
//
//  Created by MBP on 10/26/15.
//  Copyright © 2015 Grafty. All rights reserved.
//

#import "TopViewLayerLandScapeLeft.h"
#import <QuartzCore/QuartzCore.h>
#import "TopViewLayerSettings.h"

@implementation TopViewLayerLandScapeLeft
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
    
    
    centerAdjusted = CGPointMake(self.center.x, self.center.y);
    float w=65;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        w=200;
    }
    self.circleProgressWithLabel = [[KAProgressLabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.height-w, self.frame.size.height-w)];
    
    self.circleProgressWithLabel.center = centerAdjusted;
    
    self.circleProgressWithLabel.fillColor = [UIColor clearColor];
    self.circleProgressWithLabel.trackColor = [UIColor orangeColor];
    self.circleProgressWithLabel.progressColor = [UIColor greenColor];
    
    self.circleProgressWithLabel.trackWidth = 15.0;         // Defaults to 5.0
    self.circleProgressWithLabel.progressWidth = 15.0;        // Defaults to 5.0
    self.circleProgressWithLabel.roundedCornersWidth = 0; // Defaults to 0
    self.circleProgressWithLabel.progress = 0.0;
    self.circleProgressWithLabel.startLabel.text = @"test";
    //self.circleProgressWithLabel.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-270));
    
    
    //Adding tap gesture to the circle
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(circleTapAction:)];
    [tap setNumberOfTapsRequired:1];
    [self.circleProgressWithLabel addGestureRecognizer:tap];
    
    
    //Adding Mask that will clear the inside color of the Circle.
    int radius = self.circleProgressWithLabel.frame.size.width;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) cornerRadius:0];
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(self.circleProgressWithLabel.frame.origin.x, self.circleProgressWithLabel.frame.origin.y, radius, radius) cornerRadius:radius];
    [path appendPath:circlePath];
    [path setUsesEvenOddFillRule:YES];
    
    fillLayer = [CAShapeLayer layer];
    fillLayer.path = path.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.fillColor = [TopViewLayerSettings backGroundColor].CGColor;
    fillLayer.opacity = 1;
    [self.layer addSublayer:fillLayer];
    
    
    CGRect bounds = [self frame];
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
    float x=0;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        x=20; //237
    }
    //calculating y possition based on circle width
    float y= centerAdjusted.y - self.circleProgressWithLabel.frame.size.height/2.0 -35.0 ;
    if(y<0)
        y=0;

    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        
        self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(bounds.size.height/2.0-250 ,x, bounds.size.height, 40)];
    }
    else{
        self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(bounds.size.height/2.0-20 ,x, bounds.size.height, 40)];
    }
    self.infoLabel.text = @"Position face in the circle"; //default value
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    
    float fsize = 23.0F;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        fsize = 30.0F;
    }
    self.infoLabel.font = [TopViewLayerSettings labelFontWithSize:fsize];
    self.infoLabel.textColor =[TopViewLayerSettings labelColor];
    //self.infoLabel.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-270));
    //self.infoLabel.backgroundColor=[UIColor redColor];
    //add to view
    [self addSubview:self.infoLabel];
    
    //set updateLabel
    x=self.frame.size.width-15-40;
    
    //calculating y possition based on circle width
    y= self.frame.size.height- 40;
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        x=self.frame.size.width/1.5 -80;
        NSLog(@"width: %f", self.frame.size.width);
    }
    self.updateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, self.frame.size.width, 40)];
    self.updateLabel.text = @"...";//default value
    self.updateLabel.textAlignment = NSTextAlignmentCenter;
     fsize = 23.0F;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        fsize = 30.0F;
    }
    self.updateLabel.font = [TopViewLayerSettings labelFontWithSize:fsize];
    self.updateLabel.numberOfLines =1;
    self.updateLabel.textColor =[TopViewLayerSettings labelColor];
    //self.updateLabel.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-270));
    //self.updateLabel.backgroundColor=[UIColor redColor];
    //add to view
    [self addSubview:self.updateLabel];
    
    //add close button
    
    y=0;
    
    self.closeButton =[[UIButton alloc] initWithFrame:CGRectMake(0, bounds.size.height-60 , 60 , 60 )];
    
    [self.closeButton setTitle:@"CLOSE" forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.closeButton setBackgroundColor:[UIColor redColor]];
    self.closeButton.layer.cornerRadius = 5.0F;
    self.closeButton.layer.borderColor = [[TopViewLayerSettings labelColor] CGColor];
    self.closeButton.layer.borderWidth = 0.0F;
    
    //make the close button circle
    self.closeButton.layer.cornerRadius = self.closeButton.frame.size.width/2;
    self.closeButton.layer.masksToBounds = YES;
    self.closeButton.clipsToBounds = YES;
    //self.closeButton.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-270));
    
    [self addSubview:self.closeButton];
    
    
    //Heart
    float l=self.circleProgressWithLabel.frame.size.width/2.0+self.circleProgressWithLabel.center.x;
    float w_l=self.frame.size.width - l;
    
    self.heart=[[UILabel alloc] initWithFrame:CGRectMake((self.frame.size.width-w_l),  bounds.size.height/2.0-25,  w_l, 40 )];
    self.heart.text=@"";
    self.heart.textAlignment = NSTextAlignmentCenter;
    self.heart.font = [TopViewLayerSettings labelFontWithSize:30.0F];
    //self.heart.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-270));
    [self addSubview:self.heart];
    
    
    //bPMResult
    self.bPMResult =[[UILabel alloc] initWithFrame:CGRectMake((self.frame.size.width-w_l),  bounds.size.height/2.0-20,  w_l, 120 )];
    
    self.bPMResult.text = @"";//default value
    self.bPMResult.textAlignment = NSTextAlignmentCenter;
    self.bPMResult.font = [TopViewLayerSettings labelFontWithSize:30.0F];
    self.bPMResult.numberOfLines =3;
    self.bPMResult.textColor =[TopViewLayerSettings labelColor];
   // self.bPMResult.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-270));
    //self.bPMResult.backgroundColor=[UIColor redColor];
    //add to view
    [self addSubview:self.bPMResult];
    
    
    
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
    self.tapToStartLabel.frame = CGRectMake(0,self.middleCircleView.frame.size.height/2.0 - 35/2.0, self.middleCircleView.frame.size.width, 35);
    
    self.tapToStartLabel.backgroundColor = [UIColor clearColor];
    self.tapToStartLabel.alpha = 0.8;
    self.tapToStartLabel.textAlignment  = NSTextAlignmentCenter;
    self.tapToStartLabel.font = [TopViewLayerSettings labelFont];
    self.tapToStartLabel.textColor = [UIColor whiteColor];
    self.tapToStartLabel.layer.cornerRadius = 5.0;
    self.tapToStartLabel.text=@"Tap me to start...";
    //self.middleCircleView.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-270));
    [self.middleCircleView addSubview:self.tapToStartLabel];
    [self bringSubviewToFront:self.middleCircleView];
    
    //Adding tap gesture to the circle
    tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(circleTapAction:)];
    [tap setNumberOfTapsRequired:1];
    [self.middleCircleView addGestureRecognizer:tap];
    
}




@end
