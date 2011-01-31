//
//  AirMockAppDelegate.m
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/30.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import "AirMockAppDelegate.h"
#import "HTTPServer.h"
#import "AMHTTPConnection.h"

@implementation AirMockAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
    HTTPServer *httpServer = [[HTTPServer alloc] init];
    
	// Set the bonjour type of the http server.
	// This allows the server to broadcast itself via bonjour.
	// You can automatically discover the service in Safari's bonjour bookmarks section.
	[httpServer setType:@"_airmockhttp._tcp."];
    [httpServer setConnectionClass:[AMHTTPConnection class]];
//    [httpServer setPort:8080];
	
	// Serve files from the standard Sites folder
//	[httpServer setDocumentRoot:[NSURL fileURLWithPath:[@"~/Sites" stringByExpandingTildeInPath]]];
	
	NSError *error;
	BOOL success = [httpServer start:&error];
	
	if(!success)
	{
		NSLog(@"Error starting HTTP Server: %@", error);
	}
    
//    NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
//    NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
//	
//	httpServer = [HTTPServer new];
//	[httpServer setType:@"_http._tcp."];
//	
//	[httpServer setDocumentRoot:[NSURL fileURLWithPath:root]];
    
}

@end
