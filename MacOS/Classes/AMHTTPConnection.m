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

/**
 * Returns whether or not the requested resource is browseable.
**/
//- (BOOL)isBrowseable:(NSString *)path
//{
//	// Override me to provide custom configuration...
//	// You can configure it for the entire server, or based on the current request
//	
//	return YES;
//}


///**
// * This method creates a html browseable page.
// * Customize to fit your needs
//**/
//- (NSString *)createBrowseableIndex:(NSString *)path
//{
//    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
//    
//    NSMutableString *outdata = [NSMutableString new];
//	[outdata appendString:@"<html><head>"];
//	[outdata appendFormat:@"<title>Files from %@</title>", server.name];
//    [outdata appendString:@"<style>html {background-color:#eeeeee} body { background-color:#FFFFFF; font-family:Tahoma,Arial,Helvetica,sans-serif; font-size:18x; margin-left:15%; margin-right:15%; border:3px groove #006600; padding:15px; } </style>"];
//    [outdata appendString:@"</head><body>"];
//	[outdata appendFormat:@"<h1>Files from %@</h1>", server.name];
//    [outdata appendString:@"<bq>The following files are hosted live from the iPhone's Docs folder.</bq>"];
//    [outdata appendString:@"<p>"];
//	[outdata appendFormat:@"<a href=\"..\">..</a><br />\n"];
//    for (NSString *fname in array)
//    {
//        NSDictionary *fileDict = [[NSFileManager defaultManager] attributesOfItemAtPath:[path stringByAppendingPathComponent:fname] error:nil];
//		//NSLog(@"fileDict: %@", fileDict);
//        NSString *modDate = [[fileDict objectForKey:NSFileModificationDate] description];
//		if ([[fileDict objectForKey:NSFileType] isEqualToString: @"NSFileTypeDirectory"]) fname = [fname stringByAppendingString:@"/"];
//		[outdata appendFormat:@"<a href=\"%@\">%@</a>		(%8.1f Kb, %@)<br />\n", fname, fname, [[fileDict objectForKey:NSFileSize] floatValue] / 1024, modDate];
//    }
//    [outdata appendString:@"</p>"];
//	
//	if ([self supportsPOST:path withSize:0])
//	{
//		[outdata appendString:@"<form action=\"\" method=\"post\" enctype=\"multipart/form-data\" name=\"form1\" id=\"form1\">"];
//		[outdata appendString:@"<label>upload file"];
//		[outdata appendString:@"<input type=\"file\" name=\"file\" id=\"file\" />"];
//		[outdata appendString:@"</label>"];
//		[outdata appendString:@"<label>"];
//		[outdata appendString:@"<input type=\"submit\" name=\"button\" id=\"button\" value=\"Submit\" />"];
//		[outdata appendString:@"</label>"];
//		[outdata appendString:@"</form>"];
//	}
//	
//	[outdata appendString:@"</body></html>"];
//    
//	//NSLog(@"outData: %@", outdata);
//    return [outdata autorelease];
//}


//- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)relativePath
//{
//	if ([@"POST" isEqualToString:method])
//	{
//		return YES;
//	}
//	
//	return [super supportsMethod:method atPath:relativePath];
//}


/**
 * Returns whether or not the server will accept POSTs.
 * That is, whether the server will accept uploaded data for the given URI.
**/
//- (BOOL)supportsPOST:(NSString *)path withSize:(UInt64)contentLength
//{
////	NSLog(@"POST:%@", path);
//	
//	dataStartIndex = 0;
//	multipartData = [[NSMutableArray alloc] init];
//	postHeaderOK = FALSE;
//	
//	return YES;
//}


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
	
	NSString *filePath = [self filePathForURI:path];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
	{
		return [[[HTTPFileResponse alloc] initWithFilePath:filePath] autorelease];
	}
	else
	{
//		NSString *folder = [path isEqualToString:@"/"] ? [[server documentRoot] path] : [NSString stringWithFormat: @"%@%@", [[server documentRoot] path], path];

//		if ([self isBrowseable:folder])
//		{
//			//NSLog(@"folder: %@", folder);
//			NSData *browseData = [[self createBrowseableIndex:folder] dataUsingEncoding:NSUTF8StringEncoding];
//			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
//		}
	}
	
	return nil;
}


/**
 * This method is called to handle data read from a POST.
 * The given data is part of the POST body.
**/
- (void)processDataChunk:(NSData *)postDataChunk
{
	// Override me to do something useful with a POST.
	// If the post is small, such as a simple form, you may want to simply append the data to the request.
	// If the post is big, such as a file upload, you may want to store the file to disk.
	// 
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
	
	//NSLog(@"processPostDataChunk");
	
	if (!postHeaderOK)
	{
		UInt16 separatorBytes = 0x0A0D;
		NSData* separatorData = [NSData dataWithBytes:&separatorBytes length:2];
		
		int l = [separatorData length];

		for (int i = 0; i < [postDataChunk length] - l; i++)
		{
			NSRange searchRange = {i, l};

			if ([[postDataChunk subdataWithRange:searchRange] isEqualToData:separatorData])
			{
				NSRange newDataRange = {dataStartIndex, i - dataStartIndex};
				dataStartIndex = i + l;
				i += l - 1;
				NSData *newData = [postDataChunk subdataWithRange:newDataRange];

				if ([newData length])
				{
					[multipartData addObject:newData];
				}
				else
				{
					postHeaderOK = TRUE;
					
					NSString* postInfo = [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:1] bytes] length:[[multipartData objectAtIndex:1] length] encoding:NSUTF8StringEncoding];
					NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
					postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
					postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
					NSString* filename = [[[server documentRoot] path] stringByAppendingPathComponent:[postInfoComponents lastObject]];
					NSRange fileDataRange = {dataStartIndex, [postDataChunk length] - dataStartIndex};
					
					[[NSFileManager defaultManager] createFileAtPath:filename contents:[postDataChunk subdataWithRange:fileDataRange] attributes:nil];
					NSFileHandle *file = [[NSFileHandle fileHandleForUpdatingAtPath:filename] retain];

					if (file)
					{
						[file seekToEndOfFile];
						[multipartData addObject:file];
					}
					
					[postInfo release];
					
					break;
				}
			}
		}
	}
	else
	{
		[(NSFileHandle*)[multipartData lastObject] writeData:postDataChunk];
	}
}

@end