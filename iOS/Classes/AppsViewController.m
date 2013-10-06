//
//  AppListViewController.m
//  AirMockApp
//
//  Created by 徐 楽楽 on 11/01/31.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import "AppsViewController.h"
#import "CJSONDeserializer.h"
#import "TKAlertCenter.h"
#import "NSStringAdditions.h"
#import "TKImageCenter.h"
#import "UIImageAdditions.h"
#import "TapkuLibrary.h"

@interface AppsViewController()

- (void)loadData;
- (void)clearQueue;
- (NSOperationQueue *)queue;
- (void)hideLoading;

- (void)setImageForCell:(UITableViewCell *)cell withApp:(NSDictionary *)appInfo;

@end

@implementation IconTableViewCell

- (void)layoutSubviews {
    [super layoutSubviews];
//    self.imageView.bounds = CGRectMake(0,0,61,61);
    self.imageView.frame = CGRectMake(5,5,59,61);
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

@end


@implementation AppsViewController
@synthesize listURL = _listURL, loading = _loading, service = _service;

#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideLoading) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newImageRetrieved) name:kNewImageRetrieved object:nil];
    }
    return self;
}

- (void)refresh {
    [self loadData];
}

- (void)hideLoading {
    [self.loading removeFromSuperview];
}

- (TKLoadingView *)loading {
	if(_loading==nil){
		_loading  = [[TKLoadingView alloc] initWithTitle:@"Loading..."];
		[_loading startAnimating];
		_loading.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
	}
	return _loading;
}


#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 70.0;

}
/*

 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */
/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */
/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations.
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
} */

#pragma mark -
#pragma mark Data loading

- (NSOperationQueue *)queue {
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
    }
    return _queue;
}

- (void)clearQueue {
    [_queue cancelAllOperations];
    [_queue release];
    _queue = nil;    
}

- (void)dataLoaded:(NSData *)data {
    [self performSelectorOnMainThread:@selector(loadRemoteAppList:) withObject:data waitUntilDone:YES];
}

- (void)loadRemoteAppList:(NSData *)data {
    [self hideLoading];
    
    if (_apps) {
        [_apps release];
        _apps = nil;
    }
    if (_appIcons) {
        [_appIcons release];
        _appIcons = nil;
    }

    NSError *error = nil;
    _apps = [[[CJSONDeserializer deserializer] deserializeAsArray:data error:&error] retain];
    _appIcons = [[NSMutableDictionary alloc] initWithCapacity:[_apps count]];
    
    if ([_apps count] > 0) {
        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
        [[TKAlertCenter defaultCenter] postAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"%d App(s) found", nil), [_apps count]]];
    } else {
        [[TKAlertCenter defaultCenter] postAlertWithMessage:NSLocalizedString(@"No App found", nil)];
    }
    
    [self stopLoading];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.loading.title = NSLocalizedString(@"Loading", nil);
    [self.view addSubview:self.loading];
    
    [self loadData];
}

- (void)loadData {
    [self clearQueue];

    DataLoadingOperation *op = [[DataLoadingOperation alloc] init];
    op.urlString = self.listURL;
    op.delegate = self;
    [[self queue] addOperation:op];
    [op release];
}


- (void)newImageRetrieved {
    for (int i = 0; i < [_apps count]; i++) {
        NSDictionary *appInfo = [_apps objectAtIndex:i];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        [self setImageForCell:cell withApp:appInfo];
    }
}

- (void)setImageForCell:(UITableViewCell *)cell withApp:(NSDictionary *)appInfo {
    NSString *iconUrl = [appInfo valueForKey:@"icon-url"];
    NSString *bundleId = [appInfo valueForKey:@"CFBundleIdentifier"];
    
    UIImage *image = [_appIcons valueForKey:bundleId];
    if (image) {
        cell.imageView.image = image;
        return;
    }

    if (!image) image = [[TKImageCenter sharedImageCenter] imageAtURL:iconUrl queueIfNeeded:YES];

    if(image != nil){
        float s = 1.0;
        if([[UIScreen mainScreen] respondsToSelector:@selector(scale)]){
            s = [[UIScreen mainScreen] scale];
        }
        CGSize targetSize = CGSizeMake(57 * s, 57 * s);
        if (targetSize.width != image.size.width) {
            image = [image imageScaledToSize:targetSize];
        }
        image = [image imageWithRoundedCornerHeight:10.0 cornerWidth:10.0];
        cell.imageView.image = image;
        [_appIcons setValue:image forKey:bundleId];
        [cell setNeedsLayout];
    } else {
        cell.imageView.image = nil;
    }

    //somehow the tableview is to far on the top on iOS7
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
    } else {
        UIEdgeInsets inset = UIEdgeInsetsMake(65, 0, 0, 0);
        self.tableView.contentInset = inset;
    }

}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (nil == _apps) return 1;
    return [_apps count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[IconTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (nil == _apps) {
        cell.textLabel.text = NSLocalizedString(@"Pull down to load your App...", nil);
		cell.textLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
        cell.detailTextLabel.text = nil;
    } else {
        NSDictionary *appInfo = [_apps objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", 
                               [appInfo valueForKey:@"CFBundleDisplayName"], 
                               [appInfo valueForKey:@"CFBundleVersion"]];
		cell.textLabel.textColor = [UIColor blackColor];
        
        NSNumber *timeSince1970 = [appInfo valueForKey:@"updated-at"];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[timeSince1970 longValue]];
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"updated %@, %@", 
                                     [date relativeTime], [appInfo valueForKey:@"app-size"]];
        
        [self setImageForCell:cell withApp:appInfo];
    }
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (nil == _apps) return;
    
    self.loading.title = NSLocalizedString(@"Preparing app...", nil);
    [self.view addSubview:self.loading];
    
    NSDictionary *appInfo = [_apps objectAtIndex:indexPath.row];
    NSString *installUrl = [appInfo valueForKey:@"itms-services"];
#if TARGET_IPHONE_SIMULATOR
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Install" message:installUrl delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
    [self hideLoading];
#else
    //@"itms-services://?action=download-manifest&url=http://www.rakutec.com/adhoc/test.plist"
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:installUrl]];
#endif

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// Ignore the selection if there are no services as the searchingForServicesString cell
	// may be visible and tapping it would do nothing
	if ([_apps count] == 0)
		return nil;
	
	return indexPath;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [_listURL release];
    [_apps release];
    [_appIcons release];
    [_loading release];
    [_service release];
    [_queue release];
    [super dealloc];
}


@end