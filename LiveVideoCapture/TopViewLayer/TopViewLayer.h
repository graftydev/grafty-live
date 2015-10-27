//
//  TopViewLayer.h
//  LiveVideoCapture
//
//  Created by MBP on 10/26/15.
//  Copyright © 2015 Grafty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KAProgressLabel.h"

@interface TopViewLayer : UIView
@property (nonatomic, strong) KAProgressLabel   *circleProgressWithLabel;
@property (nonatomic, strong) UILabel           *infoLabel;
@property (nonatomic, strong) UILabel           *updateLabel;
@property (nonatomic, strong) UILabel           *bpmLabel;

-(id)initWithFrame:(CGRect)frame;
-(void)updateCircleLabel:(NSString*)value;
@end
