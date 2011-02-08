//
//  NSNetService+IPv4.m
//  AirTestApp
//
//  Created by 徐 楽楽 on 11/02/08.
//  Copyright 2011 ラクラクテクノロジーズ. All rights reserved.
//

#import "NSNetService+IPv4.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <arpa/inet.h>

@implementation NSNetService(IPv4)

- (NSString *)ipv4Addr {
    struct sockaddr *addr;
    char *charaddr = NULL;
    NSArray *addrs = [self addresses];
    for (NSData *a in addrs) {
        addr = (struct sockaddr *)[a bytes];
        
        if(addr->sa_family == AF_INET) {
            struct in_addr *server_addr = &((struct sockaddr_in *)addr)->sin_addr;
            charaddr = addr2ascii(AF_INET, server_addr, sizeof(struct in_addr), 0);
            return [NSString stringWithFormat:@"%s", charaddr];
        }
        //        else if(addr->sa_family == AF_INET6)
        //        {
        //            port = ntohs(((struct sockaddr_in6 *)addr)->sin6_port);
        //        }
    }
    NSLog(@"The family is neither IPv4 nor IPv6. Can't handle.");
    return nil;
}

@end
