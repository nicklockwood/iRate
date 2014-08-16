//
//  iRateAppDelegate.m
//  iRate
//
//  Created by Nick Lockwood on 26/01/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iRateAppDelegate.h"
#import "iRate.h"


@interface iRateAppDelegate () <iRateDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) UIAlertView *alertView;

@end


@implementation iRateAppDelegate

#pragma mark -
#pragma mark Application lifecycle

+ (void)initialize
{
    //set the bundle ID. normally you wouldn't need to do this
    //as it is picked up automatically from your Info.plist file
    //but we want to test with an app that's actually on the store
    [iRate sharedInstance].applicationBundleID = @"com.charcoaldesign.rainbowblocks-free";
    [iRate sharedInstance].onlyPromptIfLatestVersion = NO;

    //enable preview mode
    [iRate sharedInstance].previewMode = YES;
}

- (BOOL)application:(__unused UIApplication *)application didFinishLaunchingWithOptions:(__unused NSDictionary *)launchOptions
{    
    [self.window makeKeyAndVisible];
    return YES;
}

//in this example, we're implementing our own modal alert, so
//we use the following delegate methods to intercept and override
//the standard alert behavior

- (BOOL)iRateShouldPromptForRating
{
    if (!self.alertView)
    {
        [[[UIAlertView alloc] initWithTitle:@"Rate Me!" message:@"I'm a completely custom rating dialog. Awesome, right?" delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Rate Now", @"Maybe Later", @"Open Web Page", nil] show];
    }
    return NO;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        //ignore this version
        [iRate sharedInstance].declinedThisVersion = YES;
    }
    else if (buttonIndex == 1) // rate the app
    {
        //mark as rated
        [iRate sharedInstance].ratedThisVersion = YES;

        //launch app store
        [[iRate sharedInstance] openRatingsPageInAppStore];
    }
    else if (buttonIndex == 2) // maybe later
    {
        //remind later
        [iRate sharedInstance].lastReminded = [NSDate date];
    }
    else if (buttonIndex == 3) // maybe later
    {
        //remind later
        [iRate sharedInstance].lastReminded = [NSDate date];
    }
    else // open a web page?
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.apple.com"]];
    }
    
    self.alertView = nil;
}


@end
