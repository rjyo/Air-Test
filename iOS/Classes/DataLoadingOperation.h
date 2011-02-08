//
//  JSONLoadingOperation.h
//  Tenpura
//
//  Created by 徐 楽楽 on 10/09/04.
//  Copyright 2010 RakuRaku Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DataLoadingOperationDelegate<NSObject>

- (void)dataLoaded:(NSData *)s;

@end


@interface DataLoadingOperation : NSOperation {
    NSString *urlString;
    NSString *loadedString;
    id <DataLoadingOperationDelegate> delegate;
}

@property(nonatomic, copy) NSString *urlString;
@property(nonatomic, readonly) NSString *loadedString;
@property(nonatomic, assign) id <DataLoadingOperationDelegate> delegate;


@end
