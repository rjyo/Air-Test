/*
 
    File: BrowserViewController.m 
Abstract:  View controller for the service instance list.
This object manages a NSNetServiceBrowser configured to look for Bonjour
services.
It has an array of NSNetService objects that are displayed in a table view.
When the service browser reports that it has discovered a service, the
corresponding NSNetService is added to the array.
When a service goes away, the corresponding NSNetService is removed from the
array.
Selecting an item in the table view asynchronously resolves the corresponding
net service.
When that resolution completes, the delegate is called with the corresponding
NSNetService.
 
 Version: 2.9 
 
Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
Inc. ("Apple") in consideration of your agreement to the following 
terms, and your use, installation, modification or redistribution of 
this Apple software constitutes acceptance of these terms.  If you do 
not agree with these terms, please do not use, install, modify or 
redistribute this Apple software. 
 
In consideration of your agreement to abide by the following terms, and 
subject to these terms, Apple grants you a personal, non-exclusive 
license, under Apple's copyrights in this original Apple software (the 
"Apple Software"), to use, reproduce, modify and redistribute the Apple 
Software, with or without modifications, in source and/or binary forms; 
provided that if you redistribute the Apple Software in its entirety and 
without modifications, you must retain this notice and the following 
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Inc. may 
be used to endorse or promote products derived from the Apple Software 
without specific prior written permission from Apple.  Except as 
expressly stated in this notice, no other rights or licenses, express or 
implied, are granted by Apple herein, including but not limited to any 
patent rights that may be infringed by your derivative works or by other 
works in which the Apple Software may be incorporated. 
 
The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
 
IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE. 
 
Copyright (C) 2010 Apple Inc. All Rights Reserved. 
 
 
*/

#import "BrowserViewController.h"
#import "AppsViewController.h"
#import "NSNetService+IPv4.h"
#import "UIImageView+TKCategory.h"

#define kProgressIndicatorSize 20.0

// A category on NSNetService that's used to sort NSNetService objects by their name.
@interface NSNetService (BrowserViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService*)aService;
@end

@implementation NSNetService (BrowserViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService*)aService {
	return [[self name] localizedCaseInsensitiveCompare:[aService name]];
}
@end


@interface BrowserViewController()
@property (nonatomic, assign) BOOL showDisclosureIndicators;
@property (nonatomic, retain) NSMutableArray* services;
@property (nonatomic, retain) NSNetServiceBrowser* netServiceBrowser;
@property (nonatomic, retain) NSNetService* currentResolve;
@property (nonatomic, retain) NSTimer* timer;
@property (nonatomic, assign) BOOL needsActivityIndicator;
@property (nonatomic, assign) BOOL initialWaitOver;

- (void)stopCurrentResolve;
- (void)initialWaitOver:(NSTimer*)timer;
@end

@implementation BrowserViewController

@synthesize delegate = _delegate;
@synthesize showDisclosureIndicators = _showDisclosureIndicators;
@synthesize currentResolve = _currentResolve;
@synthesize netServiceBrowser = _netServiceBrowser;
@synthesize services = _services;
@synthesize needsActivityIndicator = _needsActivityIndicator;
@dynamic timer;
@synthesize domain = _domain;
@synthesize type = _type;
@synthesize initialWaitOver = _initialWaitOver;

- (id)initWithTitle:(NSString*)title showDisclosureIndicators:(BOOL)show {
	
	if ((self = [super initWithStyle:UITableViewStylePlain])) {
		self.title = title;
		_services = [[NSMutableArray alloc] init];
		self.showDisclosureIndicators = show;

		// Make sure we have a chance to discover devices before showing the user that nothing was found (yet)
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(initialWaitOver:) userInfo:nil repeats:NO];
	}

	return self;
}

#pragma mark -
#pragma mark View Controller Events

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:path animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark Searching

- (NSString *)searchingForServicesString {
	return _searchingForServicesString;
}

// Holds the string that's displayed in the table view during service discovery.
- (void)setSearchingForServicesString:(NSString *)searchingForServicesString {
	if (_searchingForServicesString != searchingForServicesString) {
		[_searchingForServicesString release];
		_searchingForServicesString = [searchingForServicesString copy];

        // If there are no services, reload the table to ensure that searchingForServicesString appears.
		if ([self.services count] == 0) {
			[self.tableView reloadData];
		}
	}
}

// Creates an NSNetServiceBrowser that searches for services of a particular type in a particular domain.
// If a service is currently being resolved, stop resolving it and stop the service browser from
// discovering other services.
- (BOOL)searchForServicesOfType:(NSString *)t inDomain:(NSString *)d {
    self.type = t;
    self.domain = d;
	
	[self stopCurrentResolve];
	[self.netServiceBrowser stop];
	[self.services removeAllObjects];

	NSNetServiceBrowser *aNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
	if(!aNetServiceBrowser) {
        // The NSNetServiceBrowser couldn't be allocated and initialized.
		return NO;
	}

	aNetServiceBrowser.delegate = self;
	self.netServiceBrowser = aNetServiceBrowser;
	[aNetServiceBrowser release];
	[self.netServiceBrowser searchForServicesOfType:t inDomain:d];

	[self.tableView reloadData];
	return YES;
}


- (NSTimer *)timer {
	return _timer;
}

// When this is called, invalidate the existing timer before releasing it.
- (void)setTimer:(NSTimer *)newTimer {
	[_timer invalidate];
	[newTimer retain];
	[_timer release];
	_timer = newTimer;
}

#pragma mark -
#pragma mark TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// If there are no services and searchingForServicesString is set, show one row to tell the user.
	NSUInteger count = [self.services count];
	if (count == 0 && self.searchingForServicesString && self.initialWaitOver)
		return 1;

	return count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *tableCellIdentifier = @"UITableViewCell";
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier] autorelease];
	}
	
	NSUInteger count = [self.services count];
	if (count == 0 && self.searchingForServicesString) {
        // If there are no services and searchingForServicesString is set, show one row explaining that to the user.
        cell.textLabel.text = self.searchingForServicesString;
		cell.textLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
		cell.accessoryType = UITableViewCellAccessoryNone;
        
		// Make sure to get rid of the activity indicator that may be showing if we were resolving cell zero but
		// then got didRemoveService callbacks for all services (e.g. the network connection went down).
		if (cell.accessoryView)
			cell.accessoryView = nil;
		return cell;
	}
	
	// Set up the text for the cell
	NSNetService* service = [self.services objectAtIndex:indexPath.row];
	cell.textLabel.text = [service name];
	cell.textLabel.textColor = [UIColor blackColor];
	cell.accessoryType = self.showDisclosureIndicators ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
//    cell.imageView.image = [UIImage imageNamed:@"Case.png"];

//	// Note that the underlying array could have changed, and we want to show the activity indicator on the correct cell
//	if (self.needsActivityIndicator && self.currentResolve == service) {
//		if (!cell.accessoryView) {
//			CGRect frame = CGRectMake(0.0, 0.0, kProgressIndicatorSize, kProgressIndicatorSize);
//			UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithFrame:frame];
//			[spinner startAnimating];
//			spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
//			[spinner sizeToFit];
//			spinner.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
//										UIViewAutoresizingFlexibleRightMargin |
//										UIViewAutoresizingFlexibleTopMargin |
//										UIViewAutoresizingFlexibleBottomMargin);
//			cell.accessoryView = spinner;
//			[spinner release];
//		}
//	} else if (cell.accessoryView) {
//		cell.accessoryView = nil;
//	}
//	
	return cell;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// Ignore the selection if there are no services as the searchingForServicesString cell
	// may be visible and tapping it would do nothing
	if ([self.services count] == 0)
		return nil;
	
	return indexPath;
}


- (void)stopCurrentResolve {
	self.needsActivityIndicator = NO;
	self.timer = nil;

	[self.currentResolve stop];
	self.currentResolve = nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// If another resolve was running, stop it & remove the activity indicator from that cell
	if (self.currentResolve) {
		// Get the indexPath for the active resolve cell
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[self.services indexOfObject:self.currentResolve] inSection:0];
		
		// Stop the current resolve, which will also set self.needsActivityIndicator
		[self stopCurrentResolve];
		
		// If we found the indexPath for the row, reload that cell to remove the activity indicator
		if (indexPath.row != NSNotFound)
			[self.tableView reloadRowsAtIndexPaths:[NSArray	arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
	}
	
	// Then set the current resolve to the service corresponding to the tapped cell
	self.currentResolve = [self.services objectAtIndex:indexPath.row];
	[self.currentResolve setDelegate:self];
	
	// Attempt to resolve the service. A value of 0.0 sets an unlimited time to resolve it. The user can
	// choose to cancel the resolve by selecting another service in the table view.
	[self.currentResolve resolveWithTimeout:0.0];
	
	// Make sure we give the user some feedback that the resolve is happening.
	// We will be called back asynchronously, so we don't want the user to think we're just stuck.
	// We delay showing this activity indicator in case the service is resolved quickly.
	self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(showWaiting:) userInfo:self.currentResolve repeats:NO];
}


// If necessary, sets up state to show an activity indicator to let the user know that a resolve is occuring.
- (void)showWaiting:(NSTimer*)timer {
	if (timer == self.timer) {
		NSNetService* service = (NSNetService*)[self.timer userInfo];
		if (self.currentResolve == service) {
			self.needsActivityIndicator = YES;

			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[self.services indexOfObject:self.currentResolve] inSection:0];
			if (indexPath.row != NSNotFound) {
				[self.tableView reloadRowsAtIndexPaths:[NSArray	arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
				// Deselect the row since the activity indicator shows the user something is happening.
				[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
			}
		}
	}
}

#pragma mark -
#pragma mark UI

- (void)initialWaitOver:(NSTimer*)timer {
	self.initialWaitOver= YES;
	if (![self.services count])
		[self.tableView reloadData];
}


- (void)sortAndUpdateUI {
	// Sort the services by name.
	[self.services sortUsingSelector:@selector(localizedCaseInsensitiveCompareByName:)];
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark NSNetServiceDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)service moreComing:(BOOL)moreComing {
	// If a service went away, stop resolving it if it's currently being resolved,
	// remove it from the list and update the table view if no more events are queued.
	if (self.currentResolve && [service isEqual:self.currentResolve]) {
		[self stopCurrentResolve];
	}
    if (self.navigationController.navigationItem != self.navigationItem) {
        UIViewController *vc = [[self.navigationController viewControllers] lastObject];
        if ([vc isKindOfClass:[AppsViewController class]] && [((AppsViewController *)vc).service isEqualToString:[service name]]) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
	[self.services removeObject:service];
	
	// If moreComing is NO, it means that there are no more messages in the queue from the Bonjour daemon, so we should update the UI.
	// When moreComing is set, we don't update the UI so that it doesn't 'flash'.
	if (!moreComing) {
		[self sortAndUpdateUI];
	}
}	


- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didFindService:(NSNetService*)service moreComing:(BOOL)moreComing {
	// If a service came online, add it to the list and update the table view if no more events are queued.
	[self.services addObject:service];

	// If moreComing is NO, it means that there are no more messages in the queue from the Bonjour daemon, so we should update the UI.
	// When moreComing is set, we don't update the UI so that it doesn't 'flash'.
	if (!moreComing) {
		[self sortAndUpdateUI];
	}
}	


// This should never be called, since we resolve with a timeout of 0.0, which means indefinite
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
	[self stopCurrentResolve];
	[self.tableView reloadData];
}

- (void)netServiceDidResolveAddress:(NSNetService *)service {
	assert(service == self.currentResolve);
	
    NSString *addr = [service ipv4Addr];
    int port = [service port];
    
#if TARGET_IPHONE_SIMULATOR
    //FFFF will make sure we see all apps in the simulator
    NSString *udid = @"FFFF3cac05dd2f8bed64c4d11c6077742bce974c128a";
#else
    UIDevice *device = [UIDevice currentDevice];
    NSString *udid = [device performSelector:@selector(uniqueIdentifier)];

#endif
    
    NSString *listURL = [[NSString alloc] initWithFormat:@"http://%@:%d/list/%@", addr, port, udid];
    NSLog(@"app list url: %@", listURL);
    
	[self stopCurrentResolve];
    
    // Navigation logic may go here. Create and push another view controller.
    AppsViewController *appVc = [[AppsViewController alloc] initWithStyle:UITableViewStylePlain];
    appVc.service = [service name];
    appVc.listURL = listURL;
    appVc.title = [NSString stringWithFormat:@"Apps on %@", [service name]];
    [self.navigationController pushViewController:appVc animated:YES];
    [appVc release];
}


- (void)redoSearchForServices {
    [self searchForServicesOfType:self.type inDomain:self.domain];
}


- (void)dealloc {
	// Cleanup any running resolve and free memory
	[self stopCurrentResolve];
	self.services = nil;
	[self.netServiceBrowser stop];
	self.netServiceBrowser = nil;
	[_searchingForServicesString release];
    [_type release];
    [_domain release];
	
	[super dealloc];
}


@end
