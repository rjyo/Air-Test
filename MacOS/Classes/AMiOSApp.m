//
//  AppUtils.m
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/31.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import "AMiOSApp.h"
#import "DDTTYLogger.h"
#import "NSStringAdditions.h"

@interface AMiOSApp ()

- (void)createIPAFromApp;

- (NSDictionary *)infoFromApp:(NSString *)path;

- (void)listDevicesInApp;

- (AMiOSApp *)initWithIPA:(NSString *)path;

- (NSString *)appCachePath;

- (void)getIconPath;

- (void)getFileSize;
@end


@implementation AMiOSApp
@synthesize appInfo, appPath, ipaPath, devices, iconPath, icon2xPath, fileSize, updatedAt;


// extract the IPA
- (AMiOSApp *)initWithIPA:(NSString *)path {
    self = [super init];
    if (self != nil) {
        ipaPath = [path copy];
        NSString *fileMD5 = [ipaPath getMD5String];
        NSString *cache = [self appCachePath];

        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/bin/unzip"];
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
                appInfo = [[self infoFromApp:appPath] retain];

                [self listDevicesInApp];
                [self getIconPath];
                [self getFileSize];

                NSDictionary *attributes = [fileMgr attributesOfItemAtPath:ipaPath error:nil];
                updatedAt = [[attributes valueForKey:NSFileModificationDate] retain];

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

            [self createIPAFromApp];

            [self listDevicesInApp];
            [self getIconPath];
            [self getFileSize];

            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:appPath error:nil];
            updatedAt = [[attributes valueForKey:NSFileModificationDate] retain];
        }
        return self;
    }
}

- (NSString *)appCachePath {
    NSString *myId = [[NSBundle mainBundle] bundleIdentifier];

    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingPathComponent:myId];

    NSFileManager *fileMgr = [NSFileManager defaultManager];
    [fileMgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];

    return path;
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
    [task setLaunchPath:@"/usr/bin/zip"];
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
                exceptionWithName:@"App Info Error"
                           reason:@"Failed to get information from info.plist"
                         userInfo:nil];
        @throw exception;
    }

    if (![[info valueForKey:@"DTPlatformName"] isEqualToString:@"iphoneos"]) {
        @throw [NSException exceptionWithName:@"UnSupported Platform"
                                       reason:@"This binary is not build for iOS."
                                     userInfo:nil];
    }

    return info;
}

- (void)listDevicesInApp {
    NSString *f = [appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];

    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr isReadableFileAtPath:f]) {
        @throw [NSException exceptionWithName:@"No Provisioning"
                                       reason:@"A provisioning profile is needed for install the app on iOS devices."
                                     userInfo:nil];
    }

    // todo: check if no provision
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:f];
    [fh seekToFileOffset:0x3c];
    NSData *lengthData = [fh readDataOfLength:2];
    Byte *b = (Byte *) [lengthData bytes];
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

- (void)getFileSize {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr isReadableFileAtPath:ipaPath]) {
        NSError *error;
        NSDictionary *attributes = [fileMgr attributesOfItemAtPath:ipaPath error:&error];
        fileSize = [[[attributes valueForKey:NSFileSize] readableSize] retain];
    }
}

- (void)getIconPath {
    if (nil == iconPath) {
        NSString *iconName = [appInfo valueForKey:@"CFBundleIconFile"];
        NSString *icon2xName = @"Icon@2x.png";
        if (nil == iconName) {
            NSArray *icons = [appInfo valueForKey:@"CFBundleIconFiles"];
            if ([icons count] == 1) {
                iconName = [icons objectAtIndex:0];
            }
            
            if ([icons count] == 2) {
                icon2xName = [icons objectAtIndex:1];
            }
            
            if (!icons || [icons count] == 0) {
                iconName = @"Icon.png";
            }
        }

        iconPath = [appPath stringByAppendingPathComponent:iconName];
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        if ([fileMgr isReadableFileAtPath:iconPath]) {
            [iconPath retain];
        } else {
            iconPath = [[[NSBundle mainBundle] pathForImageResource:@"noicon.png"] copy];
        }

        icon2xPath = [appPath stringByAppendingPathComponent:icon2xName];
        if ([fileMgr isReadableFileAtPath:icon2xPath]) {
            [icon2xPath retain];
        } else {
            icon2xPath = [[[NSBundle mainBundle] pathForImageResource:@"noicon@2x.png"] copy];
        }
    }
}

- (void)dealloc {
    [iconPath release];
    [ipaPath release];
    [appPath release];
    [appInfo release];
    [devices release];
    [icon2xPath release];
    [fileSize release];
    [updatedAt release];
    [super dealloc];
}

@end
