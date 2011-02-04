//
//  iRateMacAppDelegate.m
//  iRateMac
//
//  Created by Nick Lockwood on 04/02/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iRateMacAppDelegate.h"
#import "iRate.h"


@implementation iRateMacAppDelegate

@synthesize window;

+ (void)initialize
{
	//configure iRate
	[iRate sharedInstance].appStoreID = 412363063;
	[iRate sharedInstance].debug = YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application 
}

@end
