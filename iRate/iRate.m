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
NSString * const macAppStoreBundleID = @"com.apple.appstore";

NSString * const iRateiPhoneAppStoreURLFormat = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%i&onlyLatestVersion=true&pageNumber=0&sortOrdering=1";;
NSString * const iRateiPadAppStoreURLFormat = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%i";
NSString * const iRateMacAppStoreURLFormat = @"macappstore://itunes.apple.com/app/id%i";

static iRate *sharedInstance = nil;


#define SECONDS_IN_A_DAY 86400.0
#define MAC_APP_STORE_REFRESH_DELAY 1


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
@synthesize disabled;
@synthesize debug;

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
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationWillEnterForeground:)
													 name:UIApplicationWillEnterForegroundNotification
												   object:nil];
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
	if (messageTitle == nil)
	{
		self.messageTitle = [NSString stringWithFormat:@"Rate %@", applicationName];
	}
	return messageTitle;
}

- (NSString *)message
{
	if (message == nil)
	{
		self.message = [NSString stringWithFormat:@"If you enjoy using %@, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!", applicationName];
	}
	return message;
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
	[super dealloc];
}

#pragma mark -
#pragma mark Private methods

- (NSURL *)ratingURL
{
	
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		return [NSURL URLWithString:[NSString stringWithFormat:iRateiPadAppStoreURLFormat, appStoreID]];
	}
	else
	{
		return [NSURL URLWithString:[NSString stringWithFormat:iRateiPhoneAppStoreURLFormat, appStoreID]];
	}
	
#else
	
	return [NSURL URLWithString:[NSString stringWithFormat:iRateMacAppStoreURLFormat, appStoreID]];
	
#endif
	
}

- (void)incrementUseCount
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSUInteger uses = [defaults integerForKey:iRateUseCountKey];
	[defaults setInteger:uses+1 forKey:iRateUseCountKey];
	[defaults synchronize];
}

- (void)incrementEventCount
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSUInteger events = [defaults integerForKey:iRateEventCountKey];
	[defaults setInteger:events+1 forKey:iRateEventCountKey];
	[defaults synchronize];
}

- (BOOL)shouldPromptForRating
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	//check if disabled
	if (disabled)
	{
		return NO;
	}
	
	//debug mode?
	if (debug)
	{
		return YES;
	}
	
	//check if we've rated this version
	if ([[defaults objectForKey:iRateRatedVersionKey] isEqualToString:applicationVersion])
	{
		return NO;
	}
	
	//check if we've declined to rate this version
	if ([[defaults objectForKey:iRateDeclinedVersionKey] isEqualToString:applicationVersion])
	{
		return NO;
	}
	
	//check how long we've been using this version
	NSDate *firstUsed = [defaults objectForKey:iRateFirstUsedKey];
	if (firstUsed == nil || [[NSDate date] timeIntervalSinceDate:firstUsed] < (float)daysUntilPrompt * SECONDS_IN_A_DAY)
	{
		return NO;
	}
	
	//check how many times we've used it and the number of significant events
	NSUInteger used = [defaults integerForKey:iRateUseCountKey];
	NSUInteger events = [defaults integerForKey:iRateEventCountKey];
	if (used < usesUntilPrompt && events < eventsUntilPrompt)
	{
		return NO;
	}
	
	//check if within the reminder period
	NSDate *lastReminded = [defaults objectForKey:iRateLastRemindedKey];
	if (lastReminded != nil && [[NSDate date] timeIntervalSinceDate:lastReminded] < (float)remindPeriod * SECONDS_IN_A_DAY)
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
	
	//prompt user
	[self promptForRating];
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

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if (buttonIndex == alertView.cancelButtonIndex)
	{
		//ignore this version
		[defaults setObject:applicationVersion forKey:iRateDeclinedVersionKey];
		[defaults synchronize];
	}
	else if (buttonIndex == 2)
	{
		//remind later
		[defaults setObject:[NSDate date] forKey:iRateLastRemindedKey];
		[defaults synchronize];
	}
	else
	{
		//mark as rated
		[defaults setObject:applicationVersion forKey:iRateRatedVersionKey];
		[defaults synchronize];
		
		//go to ratings page
		[[UIApplication sharedApplication] openURL:[self ratingURL]];
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
		if ([macAppStoreBundleID isEqualToString:bundleID])
		{
			//open app page
			[[NSWorkspace sharedWorkspace] performSelector:@selector(openURL:) withObject:[self ratingURL] afterDelay:MAC_APP_STORE_REFRESH_DELAY];
			CFRelease(cfDict);
			return;
		}
		CFRelease(cfDict);
    }
	
	//try again
	[self performSelector:@selector(openAppPageWhenAppStoreLaunched) withObject:nil afterDelay:0];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	switch (returnCode)
	{
		case NSAlertAlternateReturn:
		{
			//ignore this version
			[defaults setObject:applicationVersion forKey:iRateDeclinedVersionKey];
			[defaults synchronize];
			break;
		}
		case NSAlertDefaultReturn:
		{
			//mark as rated
			[defaults setObject:applicationVersion forKey:iRateRatedVersionKey];
			[defaults synchronize];
			
			//launch mac app store
			[[NSWorkspace sharedWorkspace] openURL:[self ratingURL]];
			[self openAppPageWhenAppStoreLaunched];
			break;
		}
		default:
		{
			//remind later
			[defaults setObject:[NSDate date] forKey:iRateLastRemindedKey];
			[defaults synchronize];
		}
	}
}

#endif

#pragma mark -
#pragma mark Public methods

- (void)logEvent:(BOOL)deferPrompt
{
	[self incrementEventCount];
	if (!deferPrompt && [self shouldPromptForRating])
	{
		[self promptIfNetworkAvailable];
	}
}

@end