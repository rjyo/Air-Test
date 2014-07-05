//
//  AirMockAppDelegate.m
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/30.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import "AirTestAppDelegate.h"
#import "AMHTTPConnection.h"
#import "AMDataHelper.h"
#import "DDTTYLogger.h"

@implementation AirTestAppDelegate

@synthesize window, dropView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
	// Insert code here to initialize your application 
    httpServer = [[HTTPServer alloc] init];
    
	// Set the bonjour type of the http server.
	// This allows the server to broadcast itself via bonjour.
	// You can automatically discover the service in Safari's bonjour bookmarks section.
	[httpServer setType:@"_airmock._tcp."];
    [httpServer setConnectionClass:[AMHTTPConnection class]];
	//[httpServer setPort:51808];
    
	NSError *error;
	BOOL success = [httpServer start:&error];
	
	if(!success)
	{
		DDLogError(@"Error starting HTTP Server: %@", error);
	}
    
//    NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
//    NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
//	
//	[httpServer setDocumentRoot:[NSURL fileURLWithPath:root]];
    
}

- (IBAction)openAppStoreURL:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://itunes.apple.com/jp/app/idaily-pro/id390691023?mt=8#"]];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    DDLogCVerbose(@"exiting AirTest");
    
    [[AMDataHelper localHelper] deleteCache];
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
    for (NSString *fileName in filenames) {
        if ([fileName hasSuffix:@".app"] || [fileName hasSuffix:@".ipa"]) {
            [dropView openFile:fileName];
            break;
        }
    }
}

@end
