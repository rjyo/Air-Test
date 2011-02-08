//
//  AMAdditional.m
//  AppBall
//
//  Created by 徐 楽楽 on 11/02/02.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import "NSStringAdditions.h"
#import "NSDateAdditions.h"
#import <CommonCrypto/CommonDigest.h>
#define BLOCK 1024 * 1024


@implementation NSString (NSStringAdditions) 

- (NSString *)getMD5String {    
    CC_MD5_CTX c;
    
    //ファイルハンドル作成
    NSFileHandle * handle = [NSFileHandle fileHandleForReadingAtPath:self];
    
    unsigned char md5_result[CC_MD5_DIGEST_LENGTH];
    
    //初期化
    CC_MD5_Init(&c);
    
    unsigned long long endPos = [handle seekToEndOfFile]; //ファイルの終了位置を取得
    unsigned long long nowPos = 0; //ファイルの現在の位置
    [handle seekToFileOffset:nowPos];
    
    while(1){
        NSMutableData * data = [[NSMutableData alloc] init];
        //ファイルの最後までブロック以下か
        if((endPos - nowPos) >= BLOCK){
            //ファイルを１ブロック読み込む
            [data setData:[handle readDataOfLength:BLOCK]];
        } else if((endPos - nowPos) <= 0){
            break;
        } else{
            [data setData:[handle readDataOfLength:(endPos - nowPos)]];
        }
        
        char *buf = malloc([data length]);
        
        
        //読み込んだデータを取得
        [data getBytes:buf];
        //MD5値計算
        CC_MD5_Update(&c,buf,[data length]);
        
        
        //読み込み位置をデータ分ずらす
        [handle seekToFileOffset:(nowPos + [data length])];
        nowPos = nowPos + [data length];
        
        [data release];
    }
    
    CC_MD5_Final(md5_result,&c);
    
    //MD5値を文字列で取得する
    NSMutableString * resultStr = [NSMutableString string];
    int i;
    for(i=0; i < sizeof(md5_result); i++){
        [resultStr appendFormat:@"%02X", md5_result[i]];
    }
    
    return resultStr;
}

@end

@implementation NSNumber (NSNumberAdditions) 

- (NSString *)readableSize {
	float floatSize = [self floatValue];
	if (floatSize < 1023)
		return([NSString stringWithFormat:@"%i bytes",floatSize]);
    
	floatSize = floatSize / 1024;
	if (floatSize < 1023)
        return([NSString stringWithFormat:@"%1.1f KB",floatSize]);
	
    floatSize = floatSize / 1024;
	if (floatSize < 1023)
		return([NSString stringWithFormat:@"%1.1f MB",floatSize]);

	floatSize = floatSize / 1024;
	// Add as many as you like
	return([NSString stringWithFormat:@"%1.1f GB",floatSize]);
}

@end

@implementation NSDate (NSDateAdditions)

- (NSString *)relativeTime {
    int delta = -(int)[self timeIntervalSinceNow];
    
    if (delta < 60) {
        return delta == 1 ? @"one second ago" : [NSString stringWithFormat:@"%i seconds ago", delta];
    }
    
    if (delta < 120) {
        return @"a minute ago";
    }

    if (delta < 2700) {
        return [NSString stringWithFormat:@"%i minutes ago", delta/60];
    }
    if (delta < 5400) {
        return @"an hour ago";
    }
    if (delta < 24 * 3600) {
        return [NSString stringWithFormat:@"%i hours ago", delta/3600];
    }
    
    if (delta < 48 * 3600) {
        return @"yesterday";
    }
    
    if (delta < 30 * 24 * 3600) {
        return [NSString stringWithFormat:@"%i days ago", delta/(24*3600)];
    }
    
    if (delta < 12 * 30 * 24 * 3600) {
        int months = delta/(30*24*3600);
        return months <= 1 ? @"one month ago" : [NSString stringWithFormat:@"%i months ago", months];
    } else {
        int years = delta/(12*30*24*3600);
        return years <= 1 ? @"one year ago" : [NSString stringWithFormat:@"%i years ago", years];
    }
}

@end