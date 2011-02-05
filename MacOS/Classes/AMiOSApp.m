//
//  AppUtils.m
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/31.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import "AMiOSApp.h"
#import "DDTTYLogger.h"
#import "NSString+FileMD5.h"

@interface AMiOSApp()

- (void)createIPAFromApp;
- (NSDictionary *)infoFromApp:(NSString *)path;
- (void)listDevicesInApp;
- (AMiOSApp *)initWithIPA:(NSString *)path;

@end

@interface AMiOSApp()

- (NSString *)appCachePath;

@end


@implementation AMiOSApp
@synthesize appInfo, appPath, ipaPath, devices, iconPath;


// extract the IPA
- (AMiOSApp *)initWithIPA:(NSString *)path {
    self = [super init];
	if (self != nil) {
        ipaPath = [path copy];
        NSString *fileMD5 = [ipaPath getMD5String];
        NSString *cache = [self appCachePath];
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath: @"/usr/bin/unzip"];
        [task setArguments:[NSArray arrayWithObjects:@"-o", ipaPath, @"-d", fileMD5, nil]];
        [task setCurrentDirectoryPath:cache];
        [task launch];
        [task waitUntilExit];
        int status = [task terminationStatus];
        [task release];
        
        DDLogVerbose(@"Result of shell: %d", status);
        if (status != 0) {
            NSException *exception = [NSException
                                      exceptionWithName:@"FailToExtractIPAException"
                                      reason:@"Failed to extract information from .ipa file."
                                      userInfo:nil];
            @throw exception;
        }

        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSString *payloadPath = [NSString stringWithFormat:@"%@/%@/%@", cache, fileMD5, @"Payload"];
        
        NSArray *files = [fileMgr contentsOfDirectoryAtPath:payloadPath error:nil];
        for (NSString *fileName in files) {
            if ([fileName hasSuffix:@".app"]) {
                appPath = [[payloadPath stringByAppendingPathComponent:fileName] retain];
                appInfo = [[self infoFromApp:appPath] copy];
                
                [self listDevicesInApp];
                
                break;
            }
        }
	}
	return self;
}

// check app info, if iOS app, create IPA
- (AMiOSApp *)initWithPath:(NSString *)path {
    if ([path hasSuffix:@".ipa"]) {
        return [self initWithIPA:path];
    } else {
        self = [super init];
        if (self != nil) {
            appPath = [path copy];
            appInfo = [[self infoFromApp:appPath] copy];
            
            [self listDevicesInApp];
            [self createIPAFromApp];
        }
        return self;
    }
}

- (NSString *)appCachePath {
    NSString *myId = [[NSBundle mainBundle] bundleIdentifier];
    
    NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    cache = [cache stringByAppendingPathComponent:myId];

    NSFileManager *fileMgr = [NSFileManager defaultManager];
    [fileMgr createDirectoryAtPath:cache withIntermediateDirectories:YES attributes:nil error:nil];
    
    return cache;
}

- (void)createIPAFromApp {
    NSString *cache = [self appCachePath];
    cache = [cache stringByAppendingPathComponent:[appInfo valueForKey:@"CFBundleIdentifier"]];
    NSString *payload = [cache stringByAppendingPathComponent:@"Payload"];
    NSString *ipaFileName = [NSString stringWithFormat:@"%@.ipa", [appInfo valueForKey:@"CFBundleName"]];
    NSString *ipa = [cache stringByAppendingPathComponent:ipaFileName];

    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr isDeletableFileAtPath:payload]) {
        [fileMgr removeItemAtPath:cache error:nil];
    }
    [fileMgr createDirectoryAtPath:payload withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSError *error = nil;
    NSString *dest = [payload stringByAppendingPathComponent:[appPath lastPathComponent]];
    [fileMgr copyItemAtPath:appPath toPath:dest error:&error];
    
    if (error) {
        DDLogError(@"failed to copy items from %@ to %@, %@", appPath, dest, error);
        return;
    }
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/zip"];
    [task setArguments:[NSArray arrayWithObjects:@"-r", @"-y", ipa, @"Payload", nil]];
    [task setCurrentDirectoryPath:cache];
    [task launch];
    [task waitUntilExit];
    int status = [task terminationStatus];
    [task release];

    DDLogVerbose(@"Result of shell: %d", status);
    if (status != 0) {
        NSException *exception = [NSException
                                  exceptionWithName:@"FailToCreateIPAException"
                                  reason:@"Failed to create .ipa file."
                                  userInfo:nil];
        @throw exception;
    }
    
    ipaPath = [ipa copy];
}

- (NSDictionary *)infoFromApp:(NSString *)path {
    NSString *pathForPlist = [path stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:pathForPlist];
    
    if (nil == info) {
        DDLogError(@"Failed to get information from .app: %@", path);
        
        NSException *exception = [NSException
                                  exceptionWithName:@"NoAppInfoException"
                                  reason:@"Failed to get information from info.plist"
                                  userInfo:nil];
        @throw exception;
    }
    
    if (![[info valueForKey:@"DTPlatformName"] isEqualToString:@"iphoneos"]) {
        NSException *exception = [NSException
                                  exceptionWithName:@"UnSupportedPlatformException"
                                  reason:@"The binary is not build for iPhone OS"
                                  userInfo:nil];
        @throw exception;
    }
    
    return info;
}

- (void)listDevicesInApp {
    NSString *f = [appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
    // todo: check if no provision
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:f];
    [fh seekToFileOffset:0x3c];
    NSData *lengthData = [fh readDataOfLength:2];
    Byte *b = (Byte *)[lengthData bytes];
    long length = b[0] * 256 + b[1];
    [fh seekToFileOffset:0x3e];
    NSData *plistData = [fh readDataOfLength:length];
        
    NSString *error = nil;
    NSDictionary *dict = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:0 format:nil errorDescription:&error];
    devices = [[dict valueForKey:@"ProvisionedDevices"] copy];
}

- (NSDictionary *)infoFromIPA:(NSString *)path {
    NSString *pathForPlist = [path stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:pathForPlist];
    return info;
}

- (NSString *)iconPath {
    if (nil == iconPath) {
        NSString *iconName = [appInfo valueForKey:@"CFBundleIconFile"];
        if (nil == iconName) {
            NSArray *icons = [appInfo valueForKey:@"CFBundleIconFiles"];
            if ([icons count] != 0) {
                iconName = [icons objectAtIndex:0];
            } else {
                iconName = @"Icon.png";
            }
        }
        iconPath = [[appPath stringByAppendingPathComponent:iconName] copy];
    }
    return iconPath;
}

- (void)dealloc {
    [iconPath release];
    [ipaPath release];
    [appPath release];
    [appInfo release];
    [devices release];
    [super dealloc];
}

@end
