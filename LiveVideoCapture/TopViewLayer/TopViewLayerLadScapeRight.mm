//
//  TopViewLayer.m
//  LiveVideoCapture
//
//  Created by MBP on 10/26/15.
//  Copyright © 2015 Grafty. All rights reserved.
//

#import "TopViewLayerLandScapeRight.h"
#import <QuartzCore/QuartzCore.h>
#import "TopViewLayerSettings.h"

@implementation TopViewLayerLandScapeRight
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
        
        //self.transform = CGAffineTransformMakeScale(1.0, -1.0);
        //self.transform = CGAffineTransformMakeScale(-1.0, 1.0);
      
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
    
    self.circleProgressWithLabel.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270));
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
    
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
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
    
   float x=-self.frame.size.width+15+40;
    
    //calculating y possition based on circle width
    
    float y= centerAdjusted.y-20;
    if(y>self.frame.size.height)
        y= self.frame.size.height- 40;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        x=-self.frame.size.width/1.5 +80;
        NSLog(@"width: %f", self.frame.size.width);
    }
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, self.frame.size.height, 40)];
    
    
    self.infoLabel.text = @"POSITION FACE IN THE CIRCLE"; //default value
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    self.infoLabel.font = [TopViewLayerSettings labelFont];
    self.infoLabel.textColor =[TopViewLayerSettings labelColor];
    self.infoLabel.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270));
    //self.infoLabel.transform =  CGAffineTransformMakeScale(1.0, -1.0);
      //self.infoLabel.backgroundColor=[UIColor redColor];
    //add to view
    [self addSubview:self.infoLabel];
    
    //set updateLabel
     x=17;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        x=237;
    }
    //calculating y possition based on circle width
     y= centerAdjusted.y - self.circleProgressWithLabel.frame.size.height/2.0 -35.0 ;
    if(y<0)
        y=0;
    
    self.updateLabel = [[UILabel alloc] initWithFrame:CGRectMake(x ,bounds.size.height/2.0-20, bounds.size.height, 40)];
    
    self.updateLabel.text = @"...";//default value
    self.updateLabel.textAlignment = NSTextAlignmentCenter;
    self.updateLabel.font = [TopViewLayerSettings labelFontWithSize:36.0F];
    self.updateLabel.numberOfLines =1;
    self.updateLabel.textColor =[TopViewLayerSettings labelColor];
    self.updateLabel.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270));
    //self.updateLabel.backgroundColor=[UIColor redColor];
    //add to view
    [self addSubview:self.updateLabel];
    
    //add close button
    
    y=0;
    
    self.closeButton =[[UIButton alloc] initWithFrame:CGRectMake(0, self.frame.size.height-60 , 60 , 60 )];
    
    [self.closeButton setTitle:@"CLOSE" forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.closeButton setBackgroundColor:[UIColor redColor]];
    self.closeButton.layer.cornerRadius = 5.0F;
    self.closeButton.layer.borderColor = [[TopViewLayerSettings labelColor] CGColor];
    self.closeButton.layer.borderWidth = 1.0F;
    
    //make the close button circle
    self.closeButton.layer.cornerRadius = self.closeButton.frame.size.width/2;
    self.closeButton.layer.masksToBounds = YES;
    self.closeButton.clipsToBounds = YES;
    self.closeButton.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270));
    
    [self addSubview:self.closeButton];
    
    
    //Heart
    self.heart=[[UILabel alloc] initWithFrame:CGRectMake(bounds.size.width/2.0-80,  self.circleProgressWithLabel.frame.origin.y/2.0-30,  80, 40 )];
    self.heart.text= @"";//@"♥";
    self.heart.textAlignment = NSTextAlignmentCenter;
    self.heart.font = [TopViewLayerSettings labelFontWithSize:46.0F];
    self.heart.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270));
    [self addSubview:self.heart];
    
    
    //bPMResult
    self.bPMResult =[[UILabel alloc] initWithFrame:CGRectMake(bounds.size.width/2.0-40,  self.circleProgressWithLabel.frame.origin.y/2.0-70 ,  140, 120 )];
    
    self.bPMResult.text = @"";//@"60\nBPM";//default value
    self.bPMResult.textAlignment = NSTextAlignmentCenter;
    self.bPMResult.font = [TopViewLayerSettings labelFontWithSize:36.0F];
    self.bPMResult.numberOfLines =3;
    self.bPMResult.textColor =[TopViewLayerSettings labelColor];
    self.bPMResult.transform= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270));
    //self.bPMResult.backgroundColor=[TopViewLayerSettings backGroundColor];
    //add to view
    [self addSubview:self.bPMResult];
    
   
    
}




@end
