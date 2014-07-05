//
//  NSURLRequest+NSURLRequest_IgnoreSSL.m
//  AirTestApp
//
//  Created by Benjamin Kobjolke on 05.07.14.
//
//

#import "NSURLRequest+NSURLRequest_IgnoreSSL.h"

@implementation NSURLRequest (IgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host {
	return YES;
}

@end