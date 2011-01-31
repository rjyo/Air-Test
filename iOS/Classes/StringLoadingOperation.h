//
//  JSONLoadingOperation.h
//  Tenpura
//
//  Created by 徐 楽楽 on 10/09/04.
//  Copyright 2010 RakuRaku Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol StringLoadingOperationDelegate<NSObject>

- (void)stringLoaded:(NSString *)s;

@end


@interface StringLoadingOperation : NSOperation {
    NSString *urlString;
    NSString *loadedString;
    id <StringLoadingOperationDelegate> delegate;
}

@property(nonatomic, copy) NSString *urlString;
@property(nonatomic, readonly) NSString *loadedString;
@property(nonatomic, assign) id <StringLoadingOperationDelegate> delegate;


@end
