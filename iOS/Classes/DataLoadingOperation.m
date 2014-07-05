//
//  JSONLoadingOperation.m
//  Tenpura
//
//  Created by 徐 楽楽 on 10/09/04.
//  Copyright 2010 RakuRaku Technologies. All rights reserved.
//

#import "DataLoadingOperation.h"

// we need this because otherwise you can't connect to a server with a self signed certificate
//#import "NSURLRequest+NSURLRequest_IgnoreSSL.h"

@implementation DataLoadingOperation
@synthesize loadedString, urlString, delegate;

- (void)main {
    NSDate *then = [NSDate date];
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
    
    if (delegate) {
        NSDate *now = [NSDate date];
        NSTimeInterval time = [now timeIntervalSinceDate:then];
        NSLog(@"time for loading %@: %.2f", urlString, time);
        [delegate dataLoaded:data];
    }
}

- (void)dealloc {
    [urlString release];
    [loadedString release];
    [super dealloc];
}


@end
