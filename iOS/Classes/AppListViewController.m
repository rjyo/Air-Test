//
//  AppListViewController.m
//  AirMockApp
//
//  Created by 徐 楽楽 on 11/01/31.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import "AppListViewController.h"
#import "CJSONDeserializer.h"
#import "TKAlertCenter.h"
#import "TKBarButtonItem.h"

@interface AppListViewController()

- (void)loadData;
- (void)clearQueue;
- (NSOperationQueue *)queue;
- (void)hideLoading;

@end


@implementation AppListViewController
@synthesize listURL = _listURL, loading = _loading, service = _service, apps = _apps;

#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideLoading) name:UIApplicationWillResignActiveNotification object:nil];
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

/*
 - (void)viewDidLoad {
 [super viewDidLoad];
 
 // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
 // self.navigationItem.rightBarButtonItem = self.editButtonItem;
 }
 */
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (NSOperationQueue *)queue {
    if (!queue) {
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
    }
    return queue;
}

- (void)clearQueue {
    [queue cancelAllOperations];
    [queue release];
    queue = nil;    
}

- (void)dataLoaded:(NSData *)data {
    [self performSelectorOnMainThread:@selector(loadRemoteAppList:) withObject:data waitUntilDone:YES];
}

- (void)loadRemoteAppList:(NSData *)data {
    [self hideLoading];

    NSError *error = nil;
    self.apps = [[[CJSONDeserializer deserializer] deserializeAsArray:data error:&error] retain];
    
    if ([self.apps count] > 0) {
        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
        [[TKAlertCenter defaultCenter] postAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"%d App(s) found", nil), [self.apps count]]];
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
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (nil == self.apps) return 1;
    return [self.apps count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (nil == self.apps) {
        cell.textLabel.text = NSLocalizedString(@"Pull down to load your App...", nil);
		cell.textLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
        cell.detailTextLabel.text = nil;
    } else {
        NSDictionary *appInfo = [self.apps objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", 
                               [appInfo valueForKey:@"CFBundleDisplayName"], 
                               [appInfo valueForKey:@"CFBundleVersion"]];
		cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.text = [appInfo valueForKey:@"CFBundleIdentifier"];
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
    if (nil == self.apps) return;
    
    self.loading.title = NSLocalizedString(@"Preparing app...", nil);
    [self.view addSubview:self.loading];
    
    NSDictionary *appInfo = [self.apps objectAtIndex:indexPath.row];
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
	if ([self.apps count] == 0)
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
    [_loading release];
    [_service release];
    [super dealloc];
}


@end