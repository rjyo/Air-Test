//
//  AppListViewController.h
//  AirMockApp
//
//  Created by 徐 楽楽 on 11/01/31.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AppListViewController : UITableViewController {
    NSString *listURL;
    NSArray *apps;
}

@property(nonatomic, copy) NSString *listURL;

@end
