//
//  LocalDataHelper.m
//  Tenpura
//
//  Created by 徐 楽楽 on 10/09/05.
//  Copyright 2010 RakuRaku Technologies. All rights reserved.
//

#import "AMDataHelper.h"

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
        if (a && ![a valueForKey:appBundleId]) {
            [a setObject:app forKey:appBundleId];
        } else if (nil == a){
            a = [NSMutableDictionary dictionaryWithObjectsAndKeys:app, appBundleId, nil];
            [deviceMapper setObject:a forKey:udid];
        }
    }
}

- (NSArray *)allApps {
    return [appMapper allValues];
}

- (AMiOSApp *)appForBundleId:(NSString *)bundleId {
    return [appMapper valueForKey:bundleId];
}

- (NSArray *)appsForDevice:(NSString *)udid {
    NSDictionary *dict = [deviceMapper valueForKey:udid];
    return  [dict allValues];
}

- (NSString *)hostName {
    if (nil == hostName){
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        NSHost *h = [NSHost currentHost];
        hostName = [[h name] retain];
        
        [pool release];
//        NSArray *addresses = [h addresses];
//        NSString *addr;
//        
//        for (NSString *a in addresses) {
//            if (![a hasPrefix:@"127"] && [[a componentsSeparatedByString:@"."] count] == 4) {
//                hostName = [a retain];
//                break;
//            } else {
//                addr = @"IPv4 address not available" ;
//            }
//        }
    }
    
    //    
    NSLog(@"Find host name: %@", hostName);
    return hostName;
    //    return @"192.168.88.102";
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

        [self performSelectorInBackground:@selector(hostName) withObject:nil];
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
