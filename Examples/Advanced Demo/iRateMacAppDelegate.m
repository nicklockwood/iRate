//
//  iRateMacAppDelegate.m
//  iRateMac
//
//  Created by Nick Lockwood on 06/02/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iRateMacAppDelegate.h"
#import "iRate.h"


@implementation iRateMacAppDelegate

@synthesize window;
@synthesize progressIndicator;
@synthesize label;

+ (void)initialize
{
	//configure iRate
	[iRate sharedInstance].appStoreID = 412363063;
	[iRate sharedInstance].debug = NO;
    
    //prevent automatic prompt
    [iRate sharedInstance].disabled = YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	//set myself as iRate delegate
	[iRate sharedInstance].delegate = self;
}

- (IBAction)promptForRating:(id)sender;
{
	//perform manual check
	[[iRate sharedInstance] promptIfNetworkAvailable];
	[label setStringValue:@"Connecting to App Store..."];
	[progressIndicator startAnimation:self];
}

#pragma mark -
#pragma mark iVersionDelegate methods

- (void)iRateCouldNotConnectToAppStore:(NSError *)error
{
	[label setStringValue:@"Error. Could not connect."];
	[progressIndicator stopAnimation:self];
}

- (BOOL)iRateShouldPromptForRating
{
	//don't show prompt, just open app store
	[[iRate sharedInstance] openRatingsPageInAppStore];
	[label setStringValue:@"Connected."];
	[progressIndicator stopAnimation:self];
	return NO;
}

@end
