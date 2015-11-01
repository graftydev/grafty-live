//
//  HeartLabel.m
//  LiveVideoCapture
//
//  Created by MBP on 10/30/15.
//  Copyright © 2015 Grafty. All rights reserved.
//

#import "HeartLabel.h"

@implementation HeartLabel

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        self.heart = [[UILabel alloc] initWithFrame:CGRectMake(50, 5, 40, frame.size.height)];
        self.heart.textAlignment = NSTextAlignmentRight;
        self.heart.text=@"";
        //self.heart.backgroundColor=[UIColor blueColor];
        
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(40, 5, frame.size.width - 80, frame.size.height)];
        self.label.textAlignment = NSTextAlignmentCenter;
        //self.label.backgroundColor=[UIColor redColor];
        
        [self.label didChangeValueForKey:@"text"];
        [self addSubview:self.heart];
        [self addSubview:self.label];
        
        CABasicAnimation *theAnimation;
        theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
        theAnimation.duration=0.7;
        theAnimation.repeatCount=HUGE_VALF;
        theAnimation.autoreverses=YES;
        theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
        theAnimation.toValue=[NSNumber numberWithFloat:0.7];
        theAnimation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        [self.heart.layer addAnimation:theAnimation forKey:@"animateOpacity"];
        
        
    }
    return self;
}

@end
