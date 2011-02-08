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
    NSString *iconPath;
    NSString *icon2xPath;
    NSString *fileSize;
    NSDate *updatedAt;
    NSDictionary *appInfo;
    NSArray *devices;
}

@property (readonly) NSString *iconPath;
@property (readonly) NSString *icon2xPath;
@property (readonly) NSString *ipaPath; 
@property (readonly) NSString *appPath; 
@property (readonly) NSDictionary *appInfo; 
@property (readonly) NSArray *devices;
@property (readonly) NSString *fileSize;
@property (readonly) NSDate *updatedAt;

- (AMiOSApp *)initWithPath:(NSString *)path;

@end
