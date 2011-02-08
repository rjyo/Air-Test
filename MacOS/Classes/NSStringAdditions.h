//
//  AMAdditional.h
//  AppBall
//
//  Created by 徐 楽楽 on 11/02/02.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//


@interface NSString (NSStringAdditions) 

- (NSString *)getMD5String;

@end

@interface NSNumber (NSNumberAdditions) 

- (NSString *)readableSize;

@end

@interface NSDate (NSDateAdditions)
- (NSString *)relativeTime;
@end