//
//  AppListViewController.h
//  AirMockApp
//
//  Created by 徐 楽楽 on 11/01/31.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataLoadingOperation.h"
#import "PullRefreshTableViewController.h"
#import "TKLoadingView.h"

@interface IconTableViewCell : UITableViewCell

@end

@interface AppsViewController : PullRefreshTableViewController <DataLoadingOperationDelegate> {
    NSString *_listURL;
    NSArray *_apps;
    NSMutableDictionary *_appIcons;
    NSOperationQueue *_queue;
    TKLoadingView *_loading;
    NSString *_service;
}

@property(nonatomic, copy) NSString *listURL;
@property(readonly) TKLoadingView *loading;
@property(nonatomic, retain) NSString *service;

@end
