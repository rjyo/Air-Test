//
//  AirMockAppDelegate.h
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/30.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AirMockViewController;

@interface AirMockAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    AirMockViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet AirMockViewController *viewController;

@end

