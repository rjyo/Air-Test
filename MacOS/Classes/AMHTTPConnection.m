//
//  This class was created by Nonnus,
//  who graciously decided to share it with the CocoaHTTPServer community.
//

#import "AMHTTPConnection.h"
#import "AMDataHelper.h"
#import "JSON.h"

#import "HTTPServer.h"
#import "HTTPDataResponse.h"
#import "HTTPFileResponse.h"
#import "HTTPLogging.h"
#import "HTTPMessage.h"
#import "DDNumber.h"
#import "DDTTYLogger.h"


#ifdef CONFIGURATION_DEBUG
static const int httpLogLevel = HTTP_LOG_LEVEL_VERBOSE; // | HTTP_LOG_FLAG_TRACE;
#else
static const int httpLogLevel = HTTP_LOG_LEVEL_INFO; // | HTTP_LOG_FLAG_TRACE;
#endif


@implementation AMHTTPConnection

 
/**
 * This method is called to get a response for a request.
 * You may return any object that adopts the HTTPResponse protocol.
 * The HTTPServer comes with two such classes: HTTPFileResponse and HTTPDataResponse.
 * HTTPFileResponse is a wrapper for an NSFileHandle object, and is the preferred way to send a file response.
 * HTTPDataResopnse is a wrapper for an NSData object, and may be used to send a custom response.
**/
- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path {
    HTTPLogTrace();

    return NO;
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
	
	// Add support for POST
	
	if ([method isEqualToString:@"POST"])
	{
		if ([path isEqualToString:@"/post.html"])
		{
			// Let's be extra cautious, and make sure the upload isn't 5 gigs
			
			return requestContentLength < 50;
		}
	}
	
	return [super supportsMethod:method atPath:path];
}


- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    HTTPLogTrace();

    NSDate *then = [NSDate date];

	NSLog(@"httpResponseForURI: method:%@ path:%@", method, path);
    
    NSArray *args = [[path substringFromIndex:1] pathComponents];
    
    if ([args count] < 2) return nil;
    
    NSString *cmd = [args objectAtIndex:0];
    NSString *arg2 = [args objectAtIndex:1];
    
    HTTPServer *server = config.server;
    UInt16 port = [server listeningPort];
    
    if ([cmd isEqualToString:@"list"]) {
        NSArray *apps = [[AMDataHelper localHelper] appsForDevice:arg2];
        NSMutableArray *data = [NSMutableArray arrayWithCapacity:[apps count]];
        for (AMiOSApp *app in apps) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
            [dict setObject:[app.appInfo valueForKey:@"CFBundleVersion"] forKey:@"CFBundleVersion"];
            [dict setObject:[app.appInfo valueForKey:@"CFBundleIdentifier"] forKey:@"CFBundleIdentifier"];
            [dict setObject:[app.appInfo valueForKey:@"CFBundleDisplayName"] forKey:@"CFBundleDisplayName"];
            NSString *serviceUrl = @"itms-services://?action=download-manifest&url=http://%@:%d/conf/%@";
            serviceUrl = [NSString stringWithFormat:serviceUrl, 
                          [[AMDataHelper localHelper] hostName], port,
                          [app.appInfo valueForKey:@"CFBundleIdentifier"]];
            [dict setObject:serviceUrl forKey:@"itms-services"];
            [data addObject:dict];
        }
        
        NSDate *now = [NSDate date];
        NSTimeInterval time = [now timeIntervalSinceDate:then];
        NSLog(@"Get app list: %@ (%.2f)", data, time);
        
        SBJsonWriter *writer = [[SBJsonWriter alloc] init];
        return [[[HTTPDataResponse alloc] initWithData:[writer dataWithObject:data]] autorelease];
    } else if ([cmd isEqualToString:@"conf"]) {
        AMiOSApp *app = [[AMDataHelper localHelper] appForBundleId:arg2];
        if (nil == app) return nil;
        
        NSString *hostName = [[AMDataHelper localHelper] hostName];

        NSString *path = [[NSBundle mainBundle] pathForResource:@"template" ofType:@"plist"];
        NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

        NSString *appBundleId = [app.appInfo valueForKey:@"CFBundleIdentifier"];
        NSString *appName = [app.appInfo valueForKey:@"CFBundleDisplayName"];
        NSString *appVersion = [app.appInfo valueForKey:@"CFBundleVersion"];
        NSString *appURL = [NSString stringWithFormat:@"http://%@:%d/app/%@/app.ipa", hostName, port, appBundleId]; 
        NSString *iconURL = [NSString stringWithFormat:@"http://%@:%d/icon/%@/icon.png", hostName, port, appBundleId]; 
        
        NSMutableString *s = [content mutableCopy];
        [s replaceOccurrencesOfString:@"%APP_URL%" withString:appURL options:NSLiteralSearch range:NSMakeRange(0, [s length])];
        [s replaceOccurrencesOfString:@"%ICON_URL%" withString:iconURL options:NSLiteralSearch range:NSMakeRange(0, [s length])];
        [s replaceOccurrencesOfString:@"%APP_BUNDLE_ID%" withString:appBundleId options:NSLiteralSearch range:NSMakeRange(0, [s length])];
        [s replaceOccurrencesOfString:@"%APP_VERSION%" withString:appVersion options:NSLiteralSearch range:NSMakeRange(0, [s length])];
        [s replaceOccurrencesOfString:@"%APP_NAME%" withString:appName options:NSLiteralSearch range:NSMakeRange(0, [s length])];

        NSDate *now = [NSDate date];
        NSTimeInterval time = [now timeIntervalSinceDate:then];
        NSLog(@"Get app config: %@ (%.2f)", s, time);

        return [[[HTTPDataResponse alloc] initWithData:[s dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
    } else if ([cmd isEqualToString:@"app"]) {
        AMiOSApp *app = [[AMDataHelper localHelper] appForBundleId:arg2];
        if (nil == app) return nil;
        
        NSDate *now = [NSDate date];
        NSTimeInterval time = [now timeIntervalSinceDate:then];
        NSLog(@"Get app binary: %@ (%.2f)", arg2, time);
        return [[[HTTPFileResponse alloc] initWithFilePath:app.ipaPath forConnection:self] autorelease];
    } else if ([cmd isEqualToString:@"icon"]) {
        AMiOSApp *app = [[AMDataHelper localHelper] appForBundleId:arg2];
        if (nil == app) return nil;

        NSDate *now = [NSDate date];
        NSTimeInterval time = [now timeIntervalSinceDate:then];
        NSLog(@"Get icon binary: %@ (%.2f)", arg2, time);
        return [[[HTTPFileResponse alloc] initWithFilePath:app.iconPath forConnection:self] autorelease];
    }

	return nil;
}


@end