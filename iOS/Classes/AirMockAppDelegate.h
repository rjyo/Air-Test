//
//  AirMockAppDelegate.h
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/30.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BonjourBrowserController.h"

@class AirMockViewController;

@interface AirMockAppDelegate : NSObject <UIApplicationDelegate, BonjourBrowserDelegate> {
    UIWindow *window;
    BonjourBrowserController *browser;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) BonjourBrowserController *browser;

@end

