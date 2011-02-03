//
//  AppIconControl.m
//  AppBall
//
//  Created by 徐 楽楽 on 11/02/03.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import "AppIconControl.h"
#import "NSBitmapImageRep-Additions.h"

@implementation AppIconCell
@synthesize title, subtitle, image;

#define TITLE_Y 20.0
#define TITLE_HEIGHT 18.0
#define ICON_X 15.0
#define ICON_Y TITLE_Y + TITLE_HEIGHT + 5.0
#define TEXT_PADDING 4.0
#define SUBTITLE_HEIGHT 15.0

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSPoint iconPoint = NSMakePoint(ICON_X, ICON_Y);

//    if ([self state] == NSOnState) {
//        NSRect ringRect = NSMakeRect(iconPoint.x, iconPoint.y, [image size].width, [image size].width);
//        ringRect.origin.x -= 10.0;
//        ringRect.origin.y -= 10.0;
//        ringRect.size.width += 20.0;
//        ringRect.size.height += 18.0;
//        
//        [NSGraphicsContext saveGraphicsState];
//        NSSetFocusRingStyle(NSFocusRingOnly);
//        [[NSBezierPath bezierPathWithRect: NSInsetRect(ringRect, 4.0, 4.0)] fill];
//        [NSGraphicsContext restoreGraphicsState];
//    }
    
    [NSGraphicsContext saveGraphicsState];

    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowBlurRadius:3.0f];
    [shadow setShadowOffset:NSMakeSize(0.0f, -2.0f)];
    [shadow setShadowColor:[NSColor darkGrayColor]];
    [shadow set];

    [image drawAtPoint:iconPoint fromRect:NSMakeRect(0, 0, [image size].width, [image size].height) 
             operation:NSCompositeSourceOver fraction:1.0];
    
    [NSGraphicsContext restoreGraphicsState];
    
    NSRect titleRect = NSMakeRect(TEXT_PADDING, TITLE_Y, cellFrame.size.width - TEXT_PADDING * 2, TITLE_HEIGHT);
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSCenterTextAlignment];
    NSMutableDictionary *attr = [NSMutableDictionary dictionary];
    [attr setObject:style forKey:NSParagraphStyleAttributeName];
    [attr setObject:[NSFont boldSystemFontOfSize:13.0] forKey:NSFontAttributeName];
    [title drawInRect:titleRect withAttributes:attr];
    [style release];
    
    titleRect.origin.y -= SUBTITLE_HEIGHT;
    [attr setObject:[NSFont systemFontOfSize:11.0] forKey:NSFontAttributeName];
    [attr setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
    [subtitle drawInRect:titleRect withAttributes:attr];
}

- (void)dealloc {
    [image release];
    [title release];
    [subtitle release];
    [super dealloc];
}

@end


@implementation AppIconControl
+ (void)initialize {
    if (self == [AppIconControl class]) {		// Do it once
        [self setCellClass: [AppIconCell class]];
    }
}

+ (Class)cellClass {
    return [AppIconCell class];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)setImage:(NSImage *)img {
	NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithPixelsWide:57.0 pixelsHigh:57.0 hasAlpha:YES];
	[imageRep setImage:img interpolationQuality:kCGInterpolationDefault cornerSize:10.5];
	NSData *imageData = [imageRep representationUsingType:NSPNGFileType properties:nil];
	NSImage *newImage = [[[NSImage alloc] initWithData:imageData] autorelease];

    ((AppIconCell *)[self cell]).image = newImage;
}

- (NSImage *)image {
    return ((AppIconCell *)[self cell]).image;
}

- (void)setTitle:(NSString *)t {
    ((AppIconCell *)[self cell]).title = t;
}

- (NSString *)title {
    return ((AppIconCell *)[self cell]).title;
}

- (void)setSubtitle:(NSString *)t {
    ((AppIconCell *)[self cell]).subtitle = t;
}

- (NSString *)subtitle {
    return ((AppIconCell *)[self cell]).subtitle;
}

// Like most NSControls, we don't do much ourselves....

//- (void)moveRight:(id)sender {
//    [[self cell] moveRight:sender];
//}
//
//- (void)moveLeft:(id)sender {
//    [[self cell] moveLeft:sender];
//}

//- (void)performClick:(id)sender {
//    [[self cell] performClick:sender];
//}

// ---------------------------------------------------------
//  Focus ring maintenance
// ---------------------------------------------------------

// The code that actually draws the focus ring is in AppIconCell
// become/resignFirstResponder and windowKeyStateDidChange just cause the focus ring to be redisplayed as necessary.

//- (BOOL)becomeFirstResponder {
//    BOOL okToChange = [super becomeFirstResponder];
//    if (okToChange) [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
//    return okToChange;
//}
//
//- (BOOL)resignFirstResponder {
//    BOOL okToChange = [super resignFirstResponder];
//    if (okToChange) [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
//    return okToChange;
//}
//
//- (void)windowKeyStateDidChange:(NSNotification *)notif {
//    if ([[self window] firstResponder]==self) [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
//}
//
//- (void)viewDidMoveToWindow {
//    NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
//    SEL callback = @selector(windowKeyStateDidChange:);
//    
//    // If we've been installed in a new window, unregister for notificaions in the old window...
//    [notifCenter removeObserver:self];
//    
//    // ... then register for notifications in the new window.
//    [notifCenter addObserver:self selector:callback name:NSWindowDidBecomeKeyNotification object: [self window]];
//    [notifCenter addObserver:self selector:callback name:NSWindowDidResignKeyNotification object: [self window]];
//}

//- (BOOL)acceptsFirstResponder {
//    return YES;		// Use me with the keyboard....
//}
//
//- (BOOL)needsPanelToBecomeKey {
//    return NO;		// Clicking doesn't make us key, but tabbing to us will...
//}
@end
