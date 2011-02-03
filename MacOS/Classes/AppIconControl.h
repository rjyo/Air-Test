//
//  AppIconControl.h
//  AppBall
//
//  Created by 徐 楽楽 on 11/02/03.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppIconCell : NSActionCell {
    NSImage *image;
    NSString *title;
    NSString *subtitle;
}
@property(nonatomic, retain) NSImage *image;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *subtitle;

@end


@interface AppIconControl : NSControl {

}

@property(assign) NSImage *image;
@property(assign) NSString *title;
@property(assign) NSString *subtitle;

@end
