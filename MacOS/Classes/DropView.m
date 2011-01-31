//
//  DropView.m
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/30.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import "DropView.h"
#import "AMiOSApp.h"
#import "AMDataHelper.h"

@interface DropView()

BOOL isDropOn;


- (void)highlightDropView:(BOOL)yn;

@end

static NSImage *dropOnImage = nil;
static NSImage *dropNoneImage = nil;

@implementation DropView

+ (void)initialize {
    dropOnImage = [NSImage imageNamed:@"drop_on.png"];
    dropNoneImage = [NSImage imageNamed:@"drop_none.png"];
    isDropOn = NO;
}

- (void)awakeFromNib {
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

- (void)highlightDropView:(BOOL)yn {
    if (isDropOn != yn) {
        isDropOn = yn;
        [self setNeedsDisplay:YES];
    }
}

- (void)draggingExited:(id < NSDraggingInfo >)sender {
    [self highlightDropView:NO];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        
        for (NSString *fileName in files) {
            if ([fileName hasSuffix:@".app"] || [fileName hasSuffix:@".ipa"]) {
                [self highlightDropView:YES];
                return NSDragOperationGeneric;
            }
            break; // only support one file currently
        }
    }
    
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        
        // Depending on the dragging source and modifier keys,
        // the file data may be copied or linked
//        if (sourceDragMask & NSDragOperationLink) {
//            [self addLinkToFiles:files];
//            NSLog(@"1");
//        } else {
//            NSLog(@"2");
//        }
        
        for (NSString *path in files) {
            AMiOSApp *app = [[AMiOSApp alloc] initWithApp:path];
            [[AMDataHelper localHelper] saveApp:app];
        }
    }

    [self highlightDropView:NO];
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSPoint point;
    point.x = floorf((dirtyRect.size.width - [dropOnImage size].width) / 2.0);
    point.y = 50.0;
    
    if (isDropOn) {
        [dropOnImage drawAtPoint:point fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    } else {
        [dropNoneImage drawAtPoint:point fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
}

- (void)dealloc {
    [super dealloc];
//    [dropSpotView release];
}

@end
