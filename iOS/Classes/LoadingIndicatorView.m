//
//  LoadingIndicatorView.m
//  UltimateEnglish
//
//  Created by 徐 楽楽 on 09/03/23.
//  Copyright 2009 RakuRaku Technologies. All rights reserved.
//

#import "LoadingIndicatorView.h"

@interface UIImage (LoadingIndicator)
+ (UIImage *)roundedCornerImageRect:(CGRect)rect width:(float)cw;
@end

@implementation UIImage (LoadingIndicator)

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
    CGContextSetFillColorWithColor(context, c.CGColor);
    CGContextSetStrokeColorWithColor(context, c.CGColor);
	CGContextFillRect(context, imgRect);
	CGImageRef imageMasked = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	UIImage *img = [UIImage imageWithCGImage:imageMasked];
	
	CGImageRelease(imageMasked);
	CGColorSpaceRelease(colorSpace);
	return img;
}


@end

@implementation LoadingIndicatorView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
		
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		indicator.center = self.center;
		[self addSubview:indicator];
		
		loadingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		loadingLabel.text = NSLocalizedString(@"Loading...", @"");
		loadingLabel.backgroundColor = [UIColor clearColor];
		loadingLabel.textColor = [UIColor whiteColor];
		loadingLabel.font = [UIFont boldSystemFontOfSize:14.0];
		loadingLabel.textAlignment = UITextAlignmentCenter;
		loadingLabel.numberOfLines = 3;
		loadingLabel.center = self.center;
		[self addSubview:loadingLabel];
		
		UIImage *img = [[UIImage roundedCornerImageRect:CGRectMake(0.0, 0.0, 21.0, 21.0) width:8.0] 
						stretchableImageWithLeftCapWidth:10 topCapHeight:10];
		bgView = [[UIImageView alloc] initWithImage:img];
		bgView.alpha = 0.7;
		bgView.center = self.center;
		[self insertSubview:bgView atIndex:0];
    }
    return self;
}

- (void)startAnimating {
	loadingLabel.text = NSLocalizedString(@"Loading...", @"");
	indicator.alpha = 1;
	self.alpha = 1;
	[indicator startAnimating];
	[self setNeedsLayout];
}

- (void)stopAnimating {
	self.alpha = 0;
	[indicator stopAnimating];
}

- (void)showMessage:(NSString *)str {
	indicator.alpha = 0;
	loadingLabel.alpha = 1;
	loadingLabel.text = str;
	
	[self setNeedsLayout];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	
	CGRect rect0 = [loadingLabel textRectForBounds:CGRectMake(0.0, 0.0, 100.0, 120.0) limitedToNumberOfLines:3];
	CGRect rect1;
	int padding = 15.0;
	if (indicator.alpha) {
		rect1 = indicator.frame;
	} else {
		rect1 = CGRectZero;
		padding = 0.0;
	}
	
	// 10 for top/bottom padding
	int height = rect0.size.height + rect1.size.height + 10.0 * 2 + padding;
	int y = (self.bounds.size.height - height) / 2;
	
	CGPoint p = CGPointMake(self.frame.size.width/2, y + rect1.size.height/2 + padding);
	indicator.center = p;
	
	p.y += rect1.size.height/2 + 10.0 + rect0.size.height/2;
	loadingLabel.frame = rect0;
	loadingLabel.center = p;
	
	CGRect r = CGRectMake((self.bounds.size.width - 120.0)/2, y, 120.0, height);
	bgView.frame = r;
}

- (void)dealloc {
	[bgView release];
	[indicator release];
	[loadingLabel release];
    [super dealloc];
}


@end
