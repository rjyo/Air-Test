//
//  AppListViewController.h
//  AirMockApp
//
//  Created by 徐 楽楽 on 11/01/31.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadingIndicatorView.h"
#import "DataLoadingOperation.h"

@interface AppListViewController : UITableViewController <DataLoadingOperationDelegate>{
    NSString *listURL;
    NSArray *apps;
    NSOperationQueue *queue;
    LoadingIndicatorView *indicator;
}

@property(nonatomic, copy) NSString *listURL;

@end
