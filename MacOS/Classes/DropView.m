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
#import "PNGNormalizer.h"
#import "DDTTYLogger.h"
#import <QuartzCore/QuartzCore.h>

@interface DropView()

BOOL isDropOn;

- (void)highlightDropView:(BOOL)yn;

@end

static NSImage *dropOnImage = nil;
static NSImage *dropNoneImage = nil;

@implementation DropView
@synthesize dropButton, box;

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

#define ICON_HEIGHT 85.0
#define ICON_WIDTH 85.0
#define ICON_SPACING 5.0


- (BOOL)openFile:(NSString *)file {
    int appCountThen = [[[AMDataHelper localHelper] allApps] count];
    AMiOSApp *app = nil;
    @try {
        app = [[AMiOSApp alloc] initWithPath:file];
    }
    @catch (NSException * e) {
        DDLogError(@"Error: %@", e);
        
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Unsupported format"];
        [alert setInformativeText:@"This app only handles .ipa/.app binary for iOS."];
        [alert setAlertStyle:NSWarningAlertStyle];
        
//        [alert runModal];
        [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];

        
        return NO;
    }
    [[AMDataHelper localHelper] saveApp:app];
    int appCountNow = [[[AMDataHelper localHelper] allApps] count];
    
    if (appCountThen % 4 == 0 && appCountNow % 4 == 1) {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.3];
        
        // Resize the window
        NSRect f = [self.window frame];
        f.size.height += ICON_HEIGHT + ICON_SPACING 
            + (appCountThen == 0 ? 20.0 : 0.0); // special for first time
        [[self.window animator] setFrame:f display:YES animate:YES];

        for (NSButton *btn in [[self.box contentView] subviews]) {
            NSRect r = [btn frame];
            r.origin.y += ICON_HEIGHT + ICON_SPACING;
            [[btn animator] setFrame:r];
        }
        
        [NSAnimationContext endGrouping];
    }
    
    if (appCountNow > appCountThen) {
        [self performSelector:@selector(showAppIcon:) withObject:app afterDelay:0.3];
    }
    
    return YES;
}

- (void)showAppIcon:(AMiOSApp *)app {
    int appCount = [[[AMDataHelper localHelper] allApps] count];
    int col = (appCount - 1) % 4;

    NSButton *appBtn = [[[NSButton alloc] initWithFrame:NSMakeRect(16.0 + col * ICON_WIDTH, ICON_SPACING, 
                                                                   ICON_WIDTH, ICON_HEIGHT)] autorelease];
    [appBtn setBordered:NO];
    [appBtn setImagePosition:NSImageAbove];
    
    NSImage *img = [PNGNormalizer imageWithContentsOfPNGFile:app.iconPath];
    [appBtn setImage:img];
    [appBtn setTitle:[app.appInfo valueForKey:@"CFBundleDisplayName"]];
    [appBtn setAlphaValue:0.0];
    [[appBtn cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [[appBtn cell] setImageScaling:NSImageScaleNone];
    [[self.box contentView] addSubview:appBtn];

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.3];
    [[appBtn animator] setAlphaValue:1.0];
    
    [NSAnimationContext endGrouping];
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
