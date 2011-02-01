//
//  AirMockAppDelegate.m
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/30.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import "AppBallAppDelegate.h"

#define kWebServiceType @"_airmock._tcp."
#define kInitialDomain  @"local"

@implementation AppBallAppDelegate

@synthesize window;
@synthesize browser;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.

	// Create the Bonjour Browser for Web services
	BonjourBrowserController *aBrowser = [[BonjourBrowserController alloc] initForType:kWebServiceType
														  inDomain:kInitialDomain];
	self.browser = aBrowser;
	[aBrowser release];
    
	self.browser.delegate = self;
    
	// Add the controller's view as a subview of the window
	[self.window addSubview:[self.browser view]];
    
    [self.window makeKeyAndVisible];

    return YES;
}


- (NSString *)copyStringFromTXTDict:(NSDictionary *)dict which:(NSString*)which {
	// Helper for getting information from the TXT data
	NSData* data = [dict objectForKey:which];
	NSString *resultString = nil;
	if (data) {
		resultString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	}
	return resultString;
}


- (void)bonjourBrowser:(BonjourBrowserController*)browser didResolveInstance:(NSNetService*)service {
	// Construct the URL including the port number
	// Also use the path, username and password fields that can be in the TXT record
	NSDictionary* dict = [[NSNetService dictionaryFromTXTRecordData:[service TXTRecordData]] retain];
	NSString *host = [service hostName];
	
	NSString* user = [self copyStringFromTXTDict:dict which:@"u"];
	NSString* pass = [self copyStringFromTXTDict:dict which:@"p"];
	
	NSString* portStr = @"";
	
	// Note that [NSNetService port:] returns an NSInteger in host byte order
	NSInteger port = [service port];
	if (port != 0 && port != 80)
        portStr = [[NSString alloc] initWithFormat:@":%d",port];
	
	NSString* path = [self copyStringFromTXTDict:dict which:@"path"];
	if (!path || [path length]==0) {
        [path release];
        path = [[NSString alloc] initWithString:@"/"];
	} else if (![[path substringToIndex:1] isEqual:@"/"]) {
        NSString *tempPath = [[NSString alloc] initWithFormat:@"/%@",path];
        [path release];
        path = tempPath;
	}
	
	NSString* string = [[NSString alloc] initWithFormat:@"http://%@%@%@%@%@%@%@",
                        user?user:@"",
                        pass?@":":@"",
                        pass?pass:@"",
                        (user||pass)?@"@":@"",
                        host,
                        portStr,
                        path];
	
	NSURL *url = [[NSURL alloc] initWithString:string];
	[[UIApplication sharedApplication] openURL:url];
	
	[url release];
	[string release];
	[portStr release];
	[pass release];
	[user release];
	[dict release];
	[path release];
}

#pragma mark -
#pragma mark App events

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
	[browser release];
    [window release];
    [super dealloc];
}


@end
