//
//  This class was created by Nonnus,
//  who graciously decided to share it with the CocoaHTTPServer community.
//

#import "AMHTTPConnection.h"
#import "AMDataHelper.h"
#import "HTTPServer.h"
#import "HTTPResponse.h"
#import "AsyncSocket.h"
#import "JSON.h"

static NSString *hostName = nil;

@implementation AMHTTPConnection

- (NSString *)hostName {
    if (nil == hostName){
        NSHost *h = [NSHost currentHost];
//        hostName = [[h name] retain];
        NSArray *addresses = [h addresses];
        NSString *addr;
        
        for (NSString *a in addresses) {
            if (![a hasPrefix:@"127"] && [[a componentsSeparatedByString:@"."] count] == 4) {
                hostName = [a retain];
                break;
            } else {
                addr = @"IPv4 address not available" ;
            }
        }
    }
        
//    
    NSLog(@"Find host name: %@", hostName);
    return hostName;
//    return @"192.168.88.102";
} 
/**
 * This method is called to get a response for a request.
 * You may return any object that adopts the HTTPResponse protocol.
 * The HTTPServer comes with two such classes: HTTPFileResponse and HTTPDataResponse.
 * HTTPFileResponse is a wrapper for an NSFileHandle object, and is the preferred way to send a file response.
 * HTTPDataResopnse is a wrapper for an NSData object, and may be used to send a custom response.
**/
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    NSDate *then = [NSDate date];

	NSLog(@"httpResponseForURI: method:%@ path:%@", method, path);
    
    NSArray *args = [[path substringFromIndex:1] pathComponents];
    
    if ([args count] < 2) return nil;
    
    NSString *cmd = [args objectAtIndex:0];
    NSString *arg2 = [args objectAtIndex:1];
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
                          [self hostName],
                          [server port],
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
        
        NSString *hostName = [self hostName];

        NSString *path = [[NSBundle mainBundle] pathForResource:@"template" ofType:@"plist"];
        NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

        NSString *appBundleId = [app.appInfo valueForKey:@"CFBundleIdentifier"];
        NSString *appName = [app.appInfo valueForKey:@"CFBundleDisplayName"];
        NSString *appVersion = [app.appInfo valueForKey:@"CFBundleVersion"];
        NSString *appURL = [NSString stringWithFormat:@"http://%@:%d/app/%@/app.ipa", hostName, [server port], appBundleId]; 
        NSString *iconURL = [NSString stringWithFormat:@"http://%@:%d/icon/%@/icon.png", hostName, [server port], appBundleId]; 
        
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
        return [[[HTTPFileResponse alloc] initWithFilePath:app.ipaPath] autorelease];
    } else if ([cmd isEqualToString:@"icon"]) {
        AMiOSApp *app = [[AMDataHelper localHelper] appForBundleId:arg2];
        if (nil == app) return nil;

        NSString *iconName = [app.appInfo valueForKey:@"CFBundleIconFile"];
        NSString *iconPath = [app.appPath stringByAppendingPathComponent:iconName];

        NSDate *now = [NSDate date];
        NSTimeInterval time = [now timeIntervalSinceDate:then];
        NSLog(@"Get icon binary: %@ (%.2f)", arg2, time);
        return [[[HTTPFileResponse alloc] initWithFilePath:iconPath] autorelease];
    }

	
//	NSData *requestData = [(NSData *)CFHTTPMessageCopySerializedMessage(request) autorelease];
//	
//	NSString *requestStr = [[[NSString alloc] initWithData:requestData encoding:NSASCIIStringEncoding] autorelease];
//	NSLog(@"\n=== Request ====================\n%@\n================================", requestStr);
//	
//	if (requestContentLength > 0)  // Process POST data
//	{
//		NSLog(@"processing post data: %i", requestContentLength);
//		
//		if ([multipartData count] < 2) return nil;
//		
//		NSString* postInfo = [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:1] bytes]
//													  length:[[multipartData objectAtIndex:1] length]
//													encoding:NSUTF8StringEncoding];
//		
//		NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
//		postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
//		postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
//		NSString* filename = [postInfoComponents lastObject];
//		
//		if (![filename isEqualToString:@""]) //this makes sure we did not submitted upload form without selecting file
//		{
//			UInt16 separatorBytes = 0x0A0D;
//			NSMutableData* separatorData = [NSMutableData dataWithBytes:&separatorBytes length:2];
//			[separatorData appendData:[multipartData objectAtIndex:0]];
//			int l = [separatorData length];
//			int count = 2;	//number of times the separator shows up at the end of file data
//			
//			NSFileHandle* dataToTrim = [multipartData lastObject];
//			NSLog(@"data: %@", dataToTrim);
//			
//			for (unsigned long long i = [dataToTrim offsetInFile] - l; i > 0; i--)
//			{
//				[dataToTrim seekToFileOffset:i];
//				if ([[dataToTrim readDataOfLength:l] isEqualToData:separatorData])
//				{
//					[dataToTrim truncateFileAtOffset:i];
//					i -= l;
//					if (--count == 0) break;
//				}
//			}
//			
//			NSLog(@"NewFileUploaded");
//			[[NSNotificationCenter defaultCenter] postNotificationName:@"NewFileUploaded" object:nil];
//		}
//		
//		for (int n = 1; n < [multipartData count] - 1; n++)
//			NSLog(@"%@", [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:n] bytes] length:[[multipartData objectAtIndex:n] length] encoding:NSUTF8StringEncoding]);
//		
//		[postInfo release];
//		[multipartData release];
//		requestContentLength = 0;
//		
//	}
	
	return nil;
}


@end