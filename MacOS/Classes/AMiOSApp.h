//
//  AppUtils.h
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/31.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AMiOSApp : NSObject {
    NSString *ipaPath;
    NSString *appPath;
    NSDictionary *appInfo;
    NSArray *devices;
}

@property (nonatomic, copy, readonly) NSString *ipaPath; 
@property (nonatomic, copy, readonly) NSString *appPath; 
@property (nonatomic, copy, readonly) NSDictionary *appInfo; 
@property (nonatomic, copy, readonly) NSArray *devices; 

- (AMiOSApp *)initWithIPA:(NSString *)path;
- (AMiOSApp *)initWithApp:(NSString *)path;

//
//- (NSDictionary *)infoFromIPA:(NSString *)path;
//- (void)createPackageFromApp:(NSString *)appPath toIPA:(NSString *)ipaPath;

@end
