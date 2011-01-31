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
    [appMapper setObject:app forKey:[app.appInfo valueForKey:@"CFBundleIdentifier"]];
    for (NSString *udid in app.devices) {
        NSMutableArray *a = [deviceMapper valueForKey:udid];
        if (a && ![a containsObject:app]) {
            [a addObject:app];
        } else if (nil == a){
            a = [NSMutableArray array];
            [a addObject:app];
            [deviceMapper setObject:a forKey:udid];
        }
    }
}

- (AMiOSApp *)appForBundleId:(NSString *)bundleId {
    return [appMapper valueForKey:bundleId];
}

- (NSArray *)appsForDevice:(NSString *)udid {
    return [deviceMapper valueForKey:udid];
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
