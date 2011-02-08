//
//  main.m
//  AirMock
//
//  Created by 徐 楽楽 on 11/01/30.
//  Copyright 2011 RakuRaku Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h> 
#import <objc/message.h>


void Swizzle(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
		method_exchangeImplementations(origMethod, newMethod);
	
}

int main(int argc, char *argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
		
		Swizzle([UIToolbar class], @selector(drawRect:), @selector(TKdrawRect:));
		Swizzle([UINavigationBar class], @selector(drawRect:), @selector(TKdrawRect:));
		Swizzle([UINavigationController class], @selector(pushViewController:animated:), @selector(TKpushViewController:animated:));
		
	}
	
	//NSString *del = [[UIDevice currentDevice] userInterfaceIdiom] ==  UIUserInterfaceIdiomPad ? @"AppDelegate_iPad" : @"AppDelegate_iPhone";
    NSString *del = @"AirTestAppDelegate";
	int retVal = UIApplicationMain(argc, argv, nil, del);
    [pool release];
    return retVal;
}
