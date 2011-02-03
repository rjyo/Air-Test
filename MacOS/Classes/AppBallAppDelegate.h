//
//  AirMockAppDelegate.h
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/30.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HTTPServer.h"
#import "DropAppView.h"

@interface AppBallAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    HTTPServer *httpServer;
    DropAppView *dropView;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet DropAppView *dropView;

- (IBAction)openAppStoreURL:(id)sender;

@end
