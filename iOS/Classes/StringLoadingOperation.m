//
//  JSONLoadingOperation.m
//  Tenpura
//
//  Created by 徐 楽楽 on 10/09/04.
//  Copyright 2010 RakuRaku Technologies. All rights reserved.
//

#import "StringLoadingOperation.h"

@implementation StringLoadingOperation
@synthesize loadedString, urlString, delegate;

- (void)main {
    NSDate *then = [NSDate date];
//    NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlString, NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8);
//    NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlString, NULL, CFSTR("?#[]@!$&’()*+,;=\""), kCFStringEncodingUTF8);
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
    
    NSLog(@"%@", data);
//    loadedString = [[NSString stringWithCharacters:[data bytes] length:[data length]] copy];
//    loadedString = [[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil] copy];
//    [result release];
    loadedString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    if (delegate) {
        NSDate *now = [NSDate date];
        NSTimeInterval time = [now timeIntervalSinceDate:then];
        NSLog(@"time for loading: %.2f", time);
        [delegate stringLoaded:loadedString];
    }
}

- (void)dealloc {
    [urlString release];
    [loadedString release];
    [super dealloc];
}


@end
