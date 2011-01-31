//
//  LoadingIndicatorView.h
//  UltimateEnglish
//
//  Created by 徐 楽楽 on 09/03/23.
//  Copyright 2009 RakuRaku Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kLoadingIndicatorTag    100001

@interface LoadingIndicatorView : UIView {
	UIActivityIndicatorView *indicator;
	UILabel *loadingLabel;
	UIImageView *bgView;
}

- (void)startAnimating;
- (void)stopAnimating;
- (void)showMessage:(NSString *)str;
@end
