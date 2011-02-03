//
//  DropView.m
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/30.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import "DropAppView.h"
#import "AMiOSApp.h"
#import "AMDataHelper.h"
#import "PNGNormalizer.h"
#import "DDTTYLogger.h"
#import "AppIconControl.h"

#import <QuartzCore/QuartzCore.h>

#define leftArrowKeyCode                0x7B
#define rightArrowKeyCode               0x7C
#define deleteKeyCode                   0x7B

@interface DropAppView()

BOOL isDropOn;

- (void)highlightDropView:(BOOL)yn;
- (void)selectIcon:(AppIconControl *)c;

@end

static NSImage *dropOnImage = nil;
static NSImage *dropNoneImage = nil;

@implementation DropAppView
@synthesize dropButton, box, indicator;

+ (void)initialize {
    dropOnImage = [NSImage imageNamed:@"drop_on.png"];
    dropNoneImage = [NSImage imageNamed:@"drop_none.png"];
    isDropOn = NO;
}

- (void)awakeFromNib {
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    
//    NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
//    [notifCenter addObserver:self selector:@selector(onIconClick:) name:NSKeyDown object:nil];
}


- (void)highlightDropView:(BOOL)yn {
    if (isDropOn != yn) {
        isDropOn = yn;
        [dropButton setImage:yn ? dropOnImage : dropNoneImage];
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
        
        for (NSString *fileName in files) {
            if ([fileName hasSuffix:@".app"] || [fileName hasSuffix:@".ipa"]) {
                [self openFile:fileName];
                break;
            }
        }
    }

    [self highlightDropView:NO];
    return YES;
}

#pragma mark -

- (void)keyDown:(NSEvent *)theEvent {
//    NSLog(@"keydown %02X", [theEvent keyCode]);
}


#define ICON_HEIGHT 110.0
#define ICON_WIDTH 87.0 // 57x57 + 15 padding each side
#define ICON_SPACING 5.0


- (BOOL)openFile:(NSString *)file {
    [indicator startAnimation:self];
    
    int appCountThen = [[[AMDataHelper localHelper] allApps] count];
    AMiOSApp *app = nil;
    @try {
        app = [[AMiOSApp alloc] initWithPath:file];
    }
    @catch (NSException * e) {
        DDLogError(@"Error: %@", e);
        
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:[e name]];
        [alert setInformativeText:[e reason]];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];

        return NO;
    }
    @finally {
        [indicator stopAnimation:self];
    }
    [[AMDataHelper localHelper] saveApp:app];
    int appCountNow = [[[AMDataHelper localHelper] allApps] count];
    
    if (appCountThen % 4 == 0 && appCountNow % 4 == 1) {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.3];
        
        // Resize the window
        NSRect f = [self.window frame];
        CGFloat heightPlus = ICON_HEIGHT + ICON_SPACING 
            + (appCountThen == 0 ? 14.0 : 0.0);// special for first time
        f.size.height += heightPlus; 
        f.origin.y -= heightPlus;
        
        [[self.window animator] setFrame:f display:YES animate:YES];

        for (AppIconControl *control in [[self.box contentView] subviews]) {
            NSRect r = [control frame];
            r.origin.y += ICON_HEIGHT + ICON_SPACING;
            [[control animator] setFrame:r];
        }
        
        [NSAnimationContext endGrouping];
    }
    
    if (appCountNow > appCountThen) {
        [self performSelector:@selector(showAppIcon:) withObject:app afterDelay:0.3];
    }
    
    [indicator stopAnimation:self];
    return YES;
}

- (void)showAppIcon:(AMiOSApp *)app {
    int appCount = [[[AMDataHelper localHelper] allApps] count];
    int col = (appCount - 1) % 4;
    
//    AppIconControl *last = nil;
//    AppIconControl *first = nil;
    
//    if (appCount > 0) {
//        last = [[[self.box contentView] subviews] lastObject];
//        first = [[[self.box contentView] subviews] lastObject];
//    }
    
    AppIconControl *iconControl = [[[AppIconControl alloc] initWithFrame:NSMakeRect(10.0 + col * ICON_WIDTH, ICON_SPACING, 
                                                                     ICON_WIDTH, ICON_HEIGHT)] autorelease];

    NSImage *img = [PNGNormalizer imageWithContentsOfPNGFile:app.iconPath];
    iconControl.image = img;
    iconControl.title = [app.appInfo valueForKey:@"CFBundleDisplayName"];
    iconControl.subtitle = [NSString stringWithFormat:@"v %@", [app.appInfo valueForKey:@"CFBundleVersion"]];
    
    [iconControl setTarget:self];
    [iconControl setAction:@selector(onIconClick:)];
    
//    [iconControl setNextKeyView:first];
//    [last setNextKeyView:iconControl];
    
    [[self.box contentView] addSubview:iconControl];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.3];
    [[iconControl animator] setAlphaValue:1.0];
    
    [NSAnimationContext endGrouping];
    
    [self selectIcon:nil];
}

- (void)selectIcon:(AppIconControl *)c {
    for (AppIconControl *control in [[self.box contentView] subviews]) {
        if (c != control) {
            [[control cell] setState:NSOffState];
            [control setNeedsDisplay];
        }
    }
}

- (void)onIconClick:(id)sender {
    [self selectIcon:sender];
}

- (BOOL)needsPanelToBecomeKey {
    return YES;		// Clicking doesn't make us key, but tabbing to us will...
}

- (BOOL)acceptsFirstResponder {
    return YES;		// Use me with the keyboard....
}

- (IBAction)chooseApp:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setPrompt: NSLocalizedString(@"Select your app", "Preferences -> Open panel prompt")];
    [panel setAllowsMultipleSelection: NO];
    [panel setCanChooseFiles: YES];
    [panel setCanChooseDirectories: NO];
    [panel setCanCreateDirectories: NO];
    [panel setResolvesAliases:YES];
    [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"app", @"ipa", nil]];
    
    void (^appOpenPanelHandler)(NSInteger) = ^( NSInteger resultCode ) {
        if(resultCode == NSFileHandlingPanelOKButton) {
            [self openFile:[[panel URL] path]];
        }
    };
    
    [panel beginSheetModalForWindow:[self window] completionHandler:appOpenPanelHandler];
}

@end
