//
//  NSURLRequest+NSURLRequest_IgnoreSSL.h
//  AirTestApp
//
//  Created by Benjamin Kobjolke on 05.07.14.
//
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (IgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificate:(NSString*)host;

@end