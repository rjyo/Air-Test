//
//  LocalDataHelper.m
//  Tenpura
//
//  Created by 徐 楽楽 on 10/09/05.
//  Copyright 2010 RakuRaku Technologies. All rights reserved.
//

#import "AMDataHelper.h"
#import "DDTTYLogger.h"

@interface AMDataHelper (PrivateMethods)

@end


static AMDataHelper *localHelper;

@implementation AMDataHelper

#pragma mark -
#pragma mark data access methods

- (void)saveApp:(AMiOSApp *)app {
    NSString *appBundleId = [app.appInfo valueForKey:@"CFBundleIdentifier"];
    [appMapper setObject:app forKey:appBundleId];
    for (NSString *udid in app.devices) {
        NSMutableDictionary *a = [deviceMapper valueForKey:udid];
        if (a) {
            [a setObject:app forKey:appBundleId];
        } else {
            a = [NSMutableDictionary dictionaryWithObjectsAndKeys:app, appBundleId, nil];
            [deviceMapper setObject:a forKey:udid];
        }
    }
    
    if(!app.devices) {
        DDLogWarn(@"no devices found for this app - must be an enterprise app");
        NSMutableDictionary *a = [NSMutableDictionary dictionaryWithObjectsAndKeys:app, appBundleId, nil];
        [deviceMapper setObject:a forKey:@"enterprise"];
        //D DLogInfo(@"deviceMapper %@", deviceMapper);
    } else {
        //we also need to add one entry for iOS7 and above, because we can't get the UDID anymore
        NSMutableDictionary *a = [NSMutableDictionary dictionaryWithObjectsAndKeys:app, appBundleId, nil];
        [deviceMapper setObject:a forKey:@"FFFF"];
    }
}

- (NSArray *)allApps {
    return [appMapper allValues];
}

- (AMiOSApp *)appForBundleId:(NSString *)bundleId {
    return [appMapper valueForKey:bundleId];
}


- (NSArray *)appsForDevice:(NSString *)udid {
    return [self appsForDevice:udid withIOSVersion:NULL];
}


/**
 *  Get a list of apps that are compatible with the current connected device
 *  also add the enterprise apps to the list (because those work with all devices)
 *
 *  @param udid       UDID of the Device. Warning: Starting with iOS7 this is not the real UDID
 *  @param iOSVersion iOS Version like 7.1.2
 *
 *  @return array of all apps
 */
- (NSArray *)appsForDevice:(NSString *)udid withIOSVersion:(NSString *) iOSVersion {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    // we need to check if this device has >= iOS7
    // because if it does, the UDID is not correct
    BOOL isIOS7OrAbove = FALSE;
    if(iOSVersion) {
        if([iOSVersion intValue] >= 7) {
            isIOS7OrAbove = TRUE;
        }
    }
    
    if(isIOS7OrAbove || [udid hasPrefix:@"FFFF"]) {
        DDLogWarn(@"device is using iOS7 or newer, we cannot get the UDID anymore, so we show all apps");
        dict = [deviceMapper valueForKey:@"FFFF"];
        
    } else {
        dict = [deviceMapper valueForKey:udid];
    }
    
    //we also add the enterprise apps
    if(!dict) {
        dict = [deviceMapper valueForKey:@"enterprise"];
    } else {
        NSDictionary *dict2 = [deviceMapper valueForKey:@"enterprise"];
        [dict addEntriesFromDictionary:dict2];
    }

    //D DLogInfo(@"dict %@", dict);
    return  [dict allValues];
}

- (void)deleteCache {
    NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    cache = [cache stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];

    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr isDeletableFileAtPath:cache]) {
        [fileMgr removeItemAtPath:cache error:nil];
    }
}

#pragma mark -
#pragma mark methods for singleton

+ (AMDataHelper *)localHelper {
    @synchronized(self) {
        if (localHelper == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return localHelper;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (localHelper == nil) {
            localHelper = [super allocWithZone:zone];
            return localHelper;  // assignment and return on first allocation
        }
    }
	
    return nil; //on subsequent allocation attempts return nil
}

- (id)init {
	self = [super init];
	if (self != nil) {
        appMapper = [[NSMutableDictionary alloc] init];
        deviceMapper = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}



@end
