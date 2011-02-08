//
//  AppListViewController.m
//  AirMockApp
//
//  Created by 徐 楽楽 on 11/01/31.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import "AppListViewController.h"
#import "CJSONDeserializer.h"

@interface AppListViewController()

- (void)loadData;
- (void)clearQueue;
- (NSOperationQueue *)queue;

@end


@implementation AppListViewController
@synthesize listURL;

#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
        UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadData)];
        self.navigationItem.rightBarButtonItem = refreshButton;
        [refreshButton release];
    }
    return self;
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
    
    indicator = (LoadingIndicatorView *)[self.navigationController.view viewWithTag:kLoadingIndicatorTag];
    if (!indicator) {
        indicator = [[LoadingIndicatorView alloc] initWithFrame:self.view.frame];
        [self.navigationController.view addSubview:indicator];
        indicator.tag = kLoadingIndicatorTag;
    }
    float y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGRect rect = self.tableView.frame;
    rect.origin.y = y;
    indicator.frame = rect;
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
    [indicator stopAnimating];

    NSError *error = nil;
    apps = [[[CJSONDeserializer deserializer] deserializeAsArray:data error:&error] retain];

    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self loadData];
}

- (void)loadData {
    [self clearQueue];

    DataLoadingOperation *op = [[DataLoadingOperation alloc] init];
    op.urlString = self.listURL;
    op.delegate = self;
    [[self queue] addOperation:op];
    [op release];
    
    [indicator startAnimating];
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
    if (nil == apps) return 1;
    return [apps count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (nil == apps) {
        cell.textLabel.text = @"Loading apps";
    } else {
        NSDictionary *appInfo = [apps objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", 
                               [appInfo valueForKey:@"CFBundleDisplayName"], 
                               [appInfo valueForKey:@"CFBundleVersion"]];
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
    if (nil == apps) return;
    
    NSDictionary *appInfo = [apps objectAtIndex:indexPath.row];
    NSString *installUrl = [appInfo valueForKey:@"itms-services"];
#if TARGET_IPHONE_SIMULATOR
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Install" message:installUrl delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
#else
    //@"itms-services://?action=download-manifest&url=http://www.rakutec.com/adhoc/test.plist"
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:installUrl]];
#endif

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    [listURL release];
    [apps release];
    [super dealloc];
}


@end

