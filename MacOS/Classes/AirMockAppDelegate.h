//
//  AirMockAppDelegate.h
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/30.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ThreadPoolServer.h"
#import "DropView.h"

@interface AirMockAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    HTTPServer *httpServer;
    DropView *dropView;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet DropView *dropView;

@end
