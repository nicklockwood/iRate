//
//  iRate.m
//  iRate
//
//  Created by Nick Lockwood on 26/01/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iRate.h"


NSString * const iRateRatedVersionKey = @"iRateRatedVersionChecked";
NSString * const iRateDeclinedVersionKey = @"iRateDeclinedVersion";
NSString * const iRateLastRemindedKey = @"iRateLastReminded";
NSString * const iRateLastVersionUsedKey = @"iRateLastVersionUsed";
NSString * const iRateFirstUsedKey = @"iRateFirstUsed";
NSString * const iRateUseCountKey = @"iRateUseCount";
NSString * const iRateEventCountKey = @"iRateEventCount";
NSString * const iRateMacAppStoreBundleID = @"com.apple.appstore";

NSString * const iRateiOSAppStoreURLFormat = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%i";
NSString * const iRateMacAppStoreURLFormat = @"macappstore://itunes.apple.com/app/id%i";

static iRate *sharedInstance = nil;


#define SECONDS_IN_A_DAY 86400.0
#define MAC_APP_STORE_REFRESH_DELAY 2


@interface iRate()

@property (nonatomic, retain) NSString *applicationVersion;

@end


@implementation iRate

@synthesize appStoreID;
@synthesize applicationName;
@synthesize applicationVersion;
@synthesize daysUntilPrompt;
@synthesize usesUntilPrompt;
@synthesize eventsUntilPrompt;
@synthesize remindPeriod;
@synthesize messageTitle;
@synthesize message;
@synthesize cancelButtonLabel;
@synthesize remindButtonLabel;
@synthesize rateButtonLabel;
@synthesize ratingsURL;
@synthesize disabled;
@synthesize debug;
@synthesize delegate;

#pragma mark -
#pragma mark Lifecycle methods

+ (iRate *)sharedInstance
{
	if (sharedInstance == nil)
	{
		sharedInstance = [[iRate alloc] init];
	}
	return sharedInstance;
}

- (iRate *)init
{
	if ((self = [super init]))
	{
		
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
		
		//register for iphone application events
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationLaunched:)
													 name:UIApplicationDidFinishLaunchingNotification
												   object:nil];
		
		if (&UIApplicationWillEnterForegroundNotification)
		{
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(applicationWillEnterForeground:)
														 name:UIApplicationWillEnterForegroundNotification
													   object:nil];
		}
#else
		//register for mac application events
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationLaunched:)
													 name:NSApplicationDidFinishLaunchingNotification
												   object:nil];
#endif
		//application name and version
		self.applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
		self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
		
		//usage settings - these have sensible defaults
		usesUntilPrompt = 10;
		eventsUntilPrompt = 10;
		daysUntilPrompt = 10;
		remindPeriod = 1;
		
		//message text, you may wish to customise these, e.g. for localisation
		self.messageTitle = nil; //set lazily so that appname can be included
		self.message = nil; //set lazily so that appname can be included
		self.cancelButtonLabel = @"No, Thanks";
		self.remindButtonLabel = @"Remind Me Later";
		self.rateButtonLabel = @"Rate It Now";
	}
	return self;
}

- (NSString *)messageTitle
{
	if (messageTitle)
	{
		return messageTitle;
	}
	return [NSString stringWithFormat:@"Rate %@", applicationName];
}

- (NSString *)message
{
	if (message)
	{
		return message;
	}
	return [NSString stringWithFormat:@"If you enjoy using %@, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!", applicationName];
}

- (NSURL *)ratingsURL
{
	if (ratingsURL)
	{
		return ratingsURL;
	}
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
	
	return [NSURL URLWithString:[NSString stringWithFormat:iRateiOSAppStoreURLFormat, appStoreID]];
	
#else
	
	return [NSURL URLWithString:[NSString stringWithFormat:iRateMacAppStoreURLFormat, appStoreID]];
	
#endif
}

- (NSDate *)firstUsed
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:iRateFirstUsedKey];
}

- (void)setFirstUsed:(NSDate *)date
{
	[[NSUserDefaults standardUserDefaults] setObject:date forKey:iRateFirstUsedKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)lastReminded
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:iRateLastRemindedKey];
}

- (void)setLastReminded:(NSDate *)date
{
	[[NSUserDefaults standardUserDefaults] setObject:date forKey:iRateLastRemindedKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSUInteger)usesCount
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:iRateUseCountKey];
}

- (void)setUsesCount:(NSUInteger)count
{
	[[NSUserDefaults standardUserDefaults] setInteger:count forKey:iRateUseCountKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSUInteger)eventCount;
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:iRateEventCountKey];
}

- (void)setEventCount:(NSUInteger)count
{
	[[NSUserDefaults standardUserDefaults] setInteger:count forKey:iRateEventCountKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)declinedThisVersion
{
	return [[[NSUserDefaults standardUserDefaults] objectForKey:iRateDeclinedVersionKey] isEqualToString:applicationVersion];
}

- (void)setDeclinedThisVersion:(BOOL)declined
{
	[[NSUserDefaults standardUserDefaults] setObject:(declined? applicationVersion: nil) forKey:iRateDeclinedVersionKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)ratedThisVersion
{
	return [[[NSUserDefaults standardUserDefaults] objectForKey:iRateRatedVersionKey] isEqualToString:applicationVersion];
}

- (void)setRatedThisVersion:(BOOL)rated
{
	[[NSUserDefaults standardUserDefaults] setObject:(rated? applicationVersion: nil) forKey:iRateRatedVersionKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[applicationName release];
	[applicationVersion release];
	[messageTitle release];
	[message release];
	[cancelButtonLabel release];
	[remindButtonLabel release];
	[rateButtonLabel release];
	[ratingsURL release];
	[super dealloc];
}

#pragma mark -
#pragma mark Methods

- (void)incrementUseCount
{
	self.usesCount ++;
}

- (void)incrementEventCount
{
	self.eventCount ++;
}

- (BOOL)shouldPromptForRating
{
	//check if disabled
	if (disabled)
	{
		return NO;
	}
	
	//debug mode?
	else if (debug)
	{
		return YES;
	}
	
	//check if we've rated this version
	else if (self.ratedThisVersion)
	{
		return NO;
	}
	
	//check if we've declined to rate this version
	else if (self.declinedThisVersion)
	{
		return NO;
	}
	
	//check how long we've been using this version
	else if (self.firstUsed == nil || [[NSDate date] timeIntervalSinceDate:self.firstUsed] < daysUntilPrompt * SECONDS_IN_A_DAY)
	{
		return NO;
	}
	
	//check how many times we've used it and the number of significant events
	else if (self.usesCount < usesUntilPrompt && self.eventCount < eventsUntilPrompt)
	{
		return NO;
	}
	
	//check if within the reminder period
	else if (self.lastReminded != nil && [[NSDate date] timeIntervalSinceDate:self.lastReminded] < remindPeriod * SECONDS_IN_A_DAY)
	{
		return NO;
	}
	
	//lets prompt!
	return YES;
}

- (void)promptForRating
{
	
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.messageTitle
													message:self.message
												   delegate:self
										  cancelButtonTitle:cancelButtonLabel
										  otherButtonTitles:rateButtonLabel, nil];
	
	if (remindButtonLabel)
	{
		[alert addButtonWithTitle:remindButtonLabel];
	}
	
	[alert show];
	[alert release];
	
#else
	
	//only show when main window is available
	if (![[NSApplication sharedApplication] mainWindow])
	{
		[self performSelector:@selector(promptForRating) withObject:nil afterDelay:0.5];
		return;
	}
	
	NSAlert *alert = [NSAlert alertWithMessageText:self.messageTitle
									 defaultButton:rateButtonLabel
								   alternateButton:cancelButtonLabel
									   otherButton:nil
						 informativeTextWithFormat:self.message];	
	
	if (remindButtonLabel)
	{
		[alert addButtonWithTitle:remindButtonLabel];
	}
	
	[alert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow]
					  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
						contextInfo:nil];
	
#endif
	
}

- (void)promptIfNetworkAvailable
{
	//test for app store connectivity the simplest, most reliable way - by accessing apple.com
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://apple.com"] 
											 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
										 timeoutInterval:10.0];
	//send request
	[[NSURLConnection connectionWithRequest:request delegate:self] start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	//good enough; don't download any more data
	[connection cancel];
	
	//confirm with delegate
	if ([(NSObject *)delegate respondsToSelector:@selector(iRateShouldShouldPromptForRating)])
	{
		if (![delegate iRateShouldShouldPromptForRating])
		{
			return;
		}
	}
	
	//prompt user
	[self promptForRating];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	//could not connect
	if ([(NSObject *)delegate respondsToSelector:@selector(iRateCouldNotConnectToAppStore:)])
	{
		[delegate iRateCouldNotConnectToAppStore:error];
	}
}

- (void)applicationLaunched:(NSNotification *)notification
{
	//check if this is a new version
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (![[defaults objectForKey:iRateLastVersionUsedKey] isEqualToString:applicationVersion])
	{
		//reset counts
		[defaults setObject:applicationVersion forKey:iRateLastVersionUsedKey];
		[defaults setObject:[NSDate date] forKey:iRateFirstUsedKey];
		[defaults setInteger:0 forKey:iRateUseCountKey];
		[defaults setInteger:0 forKey:iRateEventCountKey];
		[defaults setObject:nil forKey:iRateLastRemindedKey];
		[defaults synchronize];
	}
	
	[self incrementUseCount];
	if ([self shouldPromptForRating])
	{
		[self promptIfNetworkAvailable];
	}
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
	[self incrementUseCount];
	if ([self shouldPromptForRating])
	{
		[self promptIfNetworkAvailable];
	}
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

- (void)openRatingsPageInAppStore
{
	[[UIApplication sharedApplication] openURL:self.ratingsURL];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == alertView.cancelButtonIndex)
	{
		//ignore this version
		self.declinedThisVersion = YES;
	}
	else if (buttonIndex == 2)
	{
		//remind later
		self.lastReminded = [NSDate date];
	}
	else
	{
		//mark as rated
		self.ratedThisVersion = YES;
		
		//go to ratings page
		[self openRatingsPageInAppStore];
	}
}

#else

- (void)openAppPageWhenAppStoreLaunched
{
	//check if app store is running
    ProcessSerialNumber psn = { kNoProcess, kNoProcess };
    while (GetNextProcess(&psn) == noErr)
	{
        CFDictionaryRef cfDict = ProcessInformationCopyDictionary(&psn,  kProcessDictionaryIncludeAllInformationMask);
		NSString *bundleID = [(NSDictionary *)cfDict objectForKey:(NSString *)kCFBundleIdentifierKey];
		if ([iRateMacAppStoreBundleID isEqualToString:bundleID])
		{
			//open app page
			[[NSWorkspace sharedWorkspace] performSelector:@selector(openURL:) withObject:self.ratingsURL afterDelay:MAC_APP_STORE_REFRESH_DELAY];
			CFRelease(cfDict);
			return;
		}
		CFRelease(cfDict);
    }
	
	//try again
	[self performSelector:@selector(openAppPageWhenAppStoreLaunched) withObject:nil afterDelay:0];
}

- (void)openRatingsPageInAppStore
{
	[[NSWorkspace sharedWorkspace] openURL:self.ratingsURL];
	[self openAppPageWhenAppStoreLaunched];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	switch (returnCode)
	{
		case NSAlertAlternateReturn:
		{
			//ignore this version
			self.declinedThisVersion = YES;
			break;
		}
		case NSAlertDefaultReturn:
		{
			//mark as rated
			self.ratedThisVersion = YES;
			
			//launch mac app store
			[self openRatingsPageInAppStore];
			break;
		}
		default:
		{
			//remind later
			self.lastReminded = [NSDate date];
		}
	}
}

#endif

- (void)logEvent:(BOOL)deferPrompt
{
	[self incrementEventCount];
	if (!deferPrompt && [self shouldPromptForRating])
	{
		[self promptIfNetworkAvailable];
	}
}

@end