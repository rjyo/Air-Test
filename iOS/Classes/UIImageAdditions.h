//
//  Fixes.h
//  AppRanks
//
//  Created by 徐 楽楽 on 09/01/21.
//  Copyright 2009 RakuRaku Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (INRoundedCornerShadow)
+ (UIImage *)imageWithRoundedCorners:(UIImage *)inputImage cornerHeight:(float)ch cornerWidth:(float)cw;
+ (UIImage *)roundedCornerImageRect:(CGRect)rect width:(float)cw;
- (UIImage *)imageScaledToSize:(CGSize)newSize ratio:(double)r offset:(CGPoint)offset;
- (UIImage *)imageScaledToSize:(CGSize)newSize;
@end

@interface UIColor (WebHexColor)
+ (UIColor *)convertWebRGBColor:(NSString*)webHexColor;
+ (UIColor *)lightCellBgColor;
+ (UIColor *)darkCellBgColor;
+ (UIColor *)lightDarkLabelColor;
+ (UIColor *)darkLabelColor;
+ (UIColor *)darkRedColor;
@end
