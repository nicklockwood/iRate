//
//  iRateAppDelegate.h
//  iRate
//
//  Created by Nick Lockwood on 26/01/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import <UIKit/UIKit.h>

@class iRateViewController;

@interface iRateAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    iRateViewController *viewController;
}

@property (nonatomic) IBOutlet UIWindow *window;
@property (nonatomic) IBOutlet iRateViewController *viewController;

@end

