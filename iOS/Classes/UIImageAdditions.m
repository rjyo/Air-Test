//
//  Fixes.m
//  AppRanks
//
//  Created by 徐 楽楽 on 09/01/21.
//  Copyright 2009 RakuRaku Technologies. All rights reserved.
//

#import "UIImageAdditions.h"

@implementation UIImage (INRoundedCornerShadow)

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight){
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

+ (UIImage *)roundedCornerImageRect:(CGRect)rect width:(float)cw {
	
	int h = rect.size.height;
	int w = rect.size.width;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
	
	CGContextBeginPath(context);
	CGRect imgRect = rect;
	imgRect.origin.x = 0;
	imgRect.origin.y = 0;
	
	addRoundedRectToPath(context, imgRect, cw, cw);
	CGContextClosePath(context);
	CGContextClip(context);
	UIColor *c = [UIColor blackColor];
	[c set];
	CGContextFillRect(context, imgRect);
	CGImageRef imageMasked = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	
	return [UIImage imageWithCGImage:imageMasked];
}


- (UIImage *)imageWithRoundedCornerHeight:(float)ch cornerWidth:(float)cw {
    float s = 1.0;
    if([[UIScreen mainScreen] respondsToSelector:@selector(scale)]){
        s = [[UIScreen mainScreen] scale];
    }
    
    ch *= s;
    cw *= s;
	
	int h = self.size.height;
	int w = self.size.width;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
	
	CGContextBeginPath(context);
	CGRect imgRect = CGRectMake(0, 0, w, h);
	addRoundedRectToPath(context, imgRect, cw, ch);
	CGContextClosePath(context);
	CGContextClip(context);
	CGContextDrawImage(context, imgRect, self.CGImage);
	CGImageRef imageMasked = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	
	float shadowOffsetY = 2 * s;
	CGContextRef context2 = CGBitmapContextCreate(NULL, w + 2 * s, h + shadowOffsetY + 2 * s, 8, 4 * (w + 2 * s), colorSpace, kCGImageAlphaPremultipliedFirst);
	CGColorRef shadowColor = [[UIColor colorWithWhite:0.1 alpha:0.5] CGColor];
	CGContextSetShadowWithColor(context2, CGSizeMake(0, -shadowOffsetY), 1.5 * s, shadowColor);
	imgRect = CGRectMake(1 * 2, shadowOffsetY + 1 * 2, w, h);
	CGContextDrawImage(context2, imgRect, imageMasked);
	CGImageRef imageShadowed = CGBitmapContextCreateImage(context2);
	
	CGContextRelease(context2);
	
	return [UIImage imageWithCGImage:imageShadowed];
}

- (UIImage *)imageScaledToSize:(CGSize)newSize {
	int h = newSize.height;
	int w = newSize.width;
    
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    
	CGContextScaleCTM(context, w/self.size.width, h/self.size.height);
	
	CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
	CGContextDrawImage(context, rect, self.CGImage);
	CGImageRef imageTrimmed = CGBitmapContextCreateImage(context);
	
	CGContextRelease(context);
	
	return [UIImage imageWithCGImage:imageTrimmed];
}


- (UIImage *)imageScaledToSize:(CGSize)newSize ratio:(double)r offset:(CGPoint)offset {
	int h = newSize.height;
	int w = newSize.width;
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);

	CGContextScaleCTM(context, r, r);
	
	CGRect rect = CGRectMake(offset.x, offset.y, self.size.width, self.size.height);
	CGContextDrawImage(context, rect, self.CGImage);
	CGImageRef imageTrimmed = CGBitmapContextCreateImage(context);
	
	CGContextRelease(context);
	
	return [UIImage imageWithCGImage:imageTrimmed];
}

@end

static UIColor *_lightDarkLabelColor;
static UIColor *_lightCellBgColor;
static UIColor *_darkCellBgColor;
static UIColor *_darkLabelColor;
static UIColor *_darkRedColor;

@implementation UIColor (WebHexColor)

+ (UIColor*)convertWebRGBColor:(NSString*)webHexColor {
	unsigned hexInt = 0;
	NSScanner *scanner = [NSScanner scannerWithString:[webHexColor stringByReplacingOccurrencesOfString:@"#" withString:@""]];
	[scanner scanHexInt:&hexInt];
	return [UIColor colorWithRed:((hexInt>>16)&0xFF)/255.0 green:((hexInt>>8)&0xFF)/255.0 blue:((hexInt)&0xFF)/255.0 alpha:1];
}

+ (UIColor *)lightDarkLabelColor {
	if (!_lightDarkLabelColor) _lightDarkLabelColor = [[UIColor convertWebRGBColor:@"#262C31"] retain];
	return _lightDarkLabelColor;
}

+ (UIColor *)darkCellBgColor {
	if (!_darkCellBgColor) _darkCellBgColor = [[UIColor convertWebRGBColor:@"#989898"] retain];
	return _darkCellBgColor;
}

+ (UIColor *)lightCellBgColor {
	if (!_lightCellBgColor) _lightCellBgColor = [[UIColor convertWebRGBColor:@"#F4F0D7"] retain];
	return _lightCellBgColor;
}

+ (UIColor *)darkLabelColor {
	if (!_darkLabelColor) _darkLabelColor = [[UIColor convertWebRGBColor:@"#1E171D"] retain];
	return _darkLabelColor;
}

+ (UIColor *)darkRedColor {
	if (!_darkRedColor) _darkRedColor = [[UIColor convertWebRGBColor:@"#FF0043"] retain];
	return _darkRedColor;
}
@end
