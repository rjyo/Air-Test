//
//  AMDataHelper.h
//  Tenpura
//
//  Created by 徐 楽楽 on 10/09/05.
//  Copyright 2010 RakuRaku Technologies. All rights reserved.
//
#import "AMiOSApp.h"

@interface AMDataHelper : NSObject {
    NSMutableDictionary *appMapper;
    NSMutableDictionary *deviceMapper;
}

- (void)saveApp:(AMiOSApp *)app;
- (NSArray *)appsForDevice:(NSString *)udid;
- (NSArray *)appsForDevice:(NSString *)udid withIOSVersion:(NSString *) iOSVersion;
- (AMiOSApp *)appForBundleId:(NSString *)bundleId;
- (NSArray *)allApps;
- (void)deleteCache;

+ (AMDataHelper *)localHelper;

@end


