//
//  TopViewLayerSettings.m
//  LiveVideoCapture
//
//  Created by MBP on 10/26/15.
//  Copyright © 2015 Grafty. All rights reserved.
//

#import "TopViewLayerSettings.h"



@implementation TopViewLayerSettings
+(UIColor*)backGroundColor{
    //R: 243 G: 253 B: 255
    //R: 241 G: 251 B: 255
    return [UIColor colorWithRed:241/255.0 green:251/255.0 blue:255/255.0 alpha:0.9];
}
+(UIColor*)labelColor{
    //R: 66 G: 182 B: 255
    return [UIColor colorWithRed:66/255.0 green:182/255.0 blue:255/255.0 alpha:1.0];
}
+(UIFont*)labelFont
{
    return [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0F];
}
@end
