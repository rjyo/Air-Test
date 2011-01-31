//
//  AppUtils.m
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/31.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import "AMiOSApp.h"

@interface AMiOSApp()

- (void)createIPAFromApp;
- (NSDictionary *)infoFromApp:(NSString *)path;
- (void)listDevicesInApp;

@end

@implementation AMiOSApp
@synthesize appInfo, appPath, ipaPath, devices;



// extract the IPA
- (AMiOSApp *)initWithIPA:(NSString *)path {
    self = [super init];
	if (self != nil) {
        ipaPath = [path copy];
	}
	return self;
}

// check app info, if iOS app, create IPA
- (AMiOSApp *)initWithApp:(NSString *)path {
    self = [super init];
	if (self != nil) {
        appPath = [path copy];
        appInfo = [[self infoFromApp:appPath] copy];
        
        if (nil != appInfo) {
            [self listDevicesInApp];
            [self createIPAFromApp];
        }
	}
	return self;
}

- (void)createIPAFromApp {
    NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    cache = [cache stringByAppendingPathComponent:@"com.rakutec.airmock"];
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
        NSLog(@"%@", error);
        return;
    }
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/zip"];
    [task setArguments:[NSArray arrayWithObjects:@"-r", @"-y", ipa, @"Payload", nil]];
    [task setCurrentDirectoryPath:cache];
    [task launch];
    ipaPath = [ipa copy];
}

- (NSDictionary *)infoFromApp:(NSString *)path {
    NSString *pathForPlist = [path stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:pathForPlist];
    return info;
}

- (void)listDevicesInApp {
    NSString *f = [appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:f];
    [fh seekToFileOffset:0x3c];
    NSData *lengthData = [fh readDataOfLength:2];
    Byte *b = (Byte *)[lengthData bytes];
    long length = b[0] * 256 + b[1];
    [fh seekToFileOffset:0x3e];
    NSData *plistData = [fh readDataOfLength:length];
    
    NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    cache = [cache stringByAppendingPathComponent:@"com.rakutec.airmock"];
    cache = [cache stringByAppendingPathComponent:[appInfo valueForKey:@"CFBundleIdentifier"]];
    
    NSString *error = nil;
    NSDictionary *dict = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:0 format:nil errorDescription:&error];
    devices = [[dict valueForKey:@"ProvisionedDevices"] copy];
}

- (NSDictionary *)infoFromIPA:(NSString *)path {
    NSString *pathForPlist = [path stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:pathForPlist];
    return info;
}

- (void)createPackageFromApp:(NSString *)appPath toIPA:(NSString *)ipaPath {
    
}

- (void)dealloc {
    [ipaPath release];
    [appPath release];
    [appInfo release];
    [devices release];
    [super dealloc];
}

@end
