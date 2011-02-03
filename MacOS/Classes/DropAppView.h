//
//  DropView.h
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/30.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DropAppView : NSView {
    NSButton *dropButton;
    NSBox *box;
    NSProgressIndicator *indicator;
}

@property (assign) IBOutlet NSButton *dropButton;
@property (assign) IBOutlet NSBox *box;
@property (assign) IBOutlet NSProgressIndicator *indicator;

- (IBAction)chooseApp:(id)sender;
- (BOOL)openFile:(NSString *)file;

@end
