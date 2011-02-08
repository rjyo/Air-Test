//
//  AirMockAppDelegate.h
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/30.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BonjourBrowserController.h"
#import "Reachability.h"

@class AirMockViewController;

@interface AirTestAppDelegate : NSObject <UIApplicationDelegate, BonjourBrowserDelegate> {
    UIWindow *window;
    BonjourBrowserController *browser;
    Reachability *_reachability;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) Reachability *reachability;
@property (nonatomic, retain) BonjourBrowserController *browser;

@end

