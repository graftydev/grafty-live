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
    return [UIColor colorWithRed:241/255.0 green:251/255.0 blue:255/255.0 alpha:1.0];
//    return [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.9];
}
+(UIColor*)labelColor{
    //R: 66 G: 182 B: 255
    return [UIColor colorWithRed:66/255.0 green:182/255.0 blue:255/255.0 alpha:1.0];
}

+(UIFont*)labelFont
{
    return [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0F];
}
+(UIFont*)labelFontWithSize:(float)size{
     return [UIFont fontWithName:@"Helvetica-Bold" size:size];
}
@end
