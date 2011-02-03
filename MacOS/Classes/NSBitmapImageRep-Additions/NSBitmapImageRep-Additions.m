//
//  NSBitmapImageRep-Additions.m
//  IconUtility
//
//  Created by boreal-kiss.com on 10/07/13.
//  Copyright 2010 boreal-kiss.com. All rights reserved.
//

#import "NSBitmapImageRep-Additions.h"

//Private
static const NSInteger DefaultBitsPerSample		= 8;
static const NSInteger DefaultSamplesPerPixel	= 4;
static const NSInteger BitsPerByte				= 8;

@implementation NSBitmapImageRep (Additions)

+(NSBitmapImageRep *)imageRepWithPixelsWide:(NSInteger)width pixelsHigh:(NSInteger)height hasAlpha:(BOOL)alpha{	
	return [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL 
													pixelsWide:width 
													pixelsHigh:height 
												 bitsPerSample:DefaultBitsPerSample 
											   samplesPerPixel:DefaultSamplesPerPixel 
													  hasAlpha:alpha 
													  isPlanar:NO 
												colorSpaceName:NSCalibratedRGBColorSpace 
												   bytesPerRow:0
												  bitsPerPixel:0] autorelease];
}


- (NSImage *)image{
	int w = [self pixelsWide];
	int h = [self pixelsHigh];
	int bpr = [self bytesPerRow];
	int bpp = [self bitsPerPixel];
	int bps = [self bitsPerSample];
	
	CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, [self bitmapData], h * bpr, NULL);
	CGImageRef cgImage = CGImageCreate(w, 
									   h, 
									   bps, 
									   bpp, 
									   bpr, 
									   [[self colorSpace] CGColorSpace], 
									   kCGImageAlphaPremultipliedLast, 
									   dataProvider, 
									   NULL, 
									   YES, 
									   kCGRenderingIntentDefault);

	CGDataProviderRelease(dataProvider);
	NSImage *nsImage = [[[NSImage alloc] initWithCGImage:cgImage size:NSZeroSize] autorelease];
	CGImageRelease(cgImage);
	
	return nsImage;
}

//
//- (NSImage *)roundedCornerImage:(NSInteger)cornerSize borderSize:(NSInteger)borderSize {
//    // If the image does not have an alpha layer, add one
//    NSImage *image = [self imageWithAlpha];
//    
//    // Build a context that's the same dimensions as the new size
//    CGContextRef context = CGBitmapContextCreate(NULL,
//                                                 image.size.width,
//                                                 image.size.height,
//                                                 CGImageGetBitsPerComponent(image.CGImage),
//                                                 0,
//                                                 CGImageGetColorSpace(image.CGImage),
//                                                 CGImageGetBitmapInfo(image.CGImage));
//    
//    // Create a clipping path with rounded corners
//    CGContextBeginPath(context);
//    [self addRoundedRectToPath:CGRectMake(borderSize, borderSize, image.size.width - borderSize * 2, image.size.height - borderSize * 2)
//                       context:context
//                     ovalWidth:cornerSize
//                    ovalHeight:cornerSize];
//    CGContextClosePath(context);
//    CGContextClip(context);
//    
//    // Draw the image to the context; the clipping path will make anything outside the rounded rect transparent
//    CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
//    
//    // Create a CGImage from the context
//    CGImageRef clippedImage = CGBitmapContextCreateImage(context);
//    CGContextRelease(context);
//    
//    // Create a UIImage from the CGImage
//    UIImage *roundedImage = [UIImage imageWithCGImage:clippedImage];
//    CGImageRelease(clippedImage);
//    
//    return roundedImage;
//}


#pragma mark -
#pragma mark Private helper methods

// Adds a rectangular path to the given context and rounds its corners by the given extents
// Original author: Björn Sållarp. Used with permission. See: http://blog.sallarp.com/iphone-uiimage-round-corners/
- (void)addRoundedRectToPath:(CGRect)rect context:(CGContextRef)context ovalWidth:(CGFloat)ovalWidth ovalHeight:(CGFloat)ovalHeight {
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    CGFloat fw = CGRectGetWidth(rect) / ovalWidth;
    CGFloat fh = CGRectGetHeight(rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}


- (void)setImage:(NSImage *)anImage interpolationQuality:(CGInterpolationQuality)quality cornerSize:(CGFloat)cornerSize{
	int w = [self pixelsWide];
	int h = [self pixelsHigh];
	int bpr = [self bytesPerRow];
	int bps = [self bitsPerSample];
	
	CGImageRef cgImage = [anImage CGImageForProposedRect:NULL context:nil hints:nil];
	
	CGContextRef context = CGBitmapContextCreate([self bitmapData], 
												 w, 
												 h, 
												 bps, 
												 bpr, 
												 [[self colorSpace] CGColorSpace], 
												 kCGImageAlphaPremultipliedLast);
	
	//Considers CG's interpolation algorithms.
	CGContextSetInterpolationQuality(context, quality);
    
    if (cornerSize != 0) {
        CGFloat borderSize = 0.0;
        
        CGContextBeginPath(context);
        [self addRoundedRectToPath:CGRectMake(borderSize, borderSize, w - borderSize * 2, h - borderSize * 2)
                           context:context
                         ovalWidth:cornerSize
                        ovalHeight:cornerSize];
        CGContextClosePath(context);
        CGContextClip(context);
        
        // Draw the image to the context; the clipping path will make anything outside the rounded rect transparent
    }
	
	CGContextDrawImage(context, CGRectMake(0, 0, w, h), cgImage);
    
	CGContextRelease(context);
}


- (void)setImage:(NSImage *)anImage {
	[self setImage:anImage interpolationQuality:kCGInterpolationDefault cornerSize:0.0];
}

@end
