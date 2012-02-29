//
//  iRate.m
//
//  Version 1.3.5
//
//  Created by Nick Lockwood on 26/01/2011.
//  Copyright 2011 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from either of these locations:
//
//  http://charcoaldesign.co.uk/source/cocoa#irate
//  https://github.com/nicklockwood/iRate
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "iRate.h"


static NSString *const iRateRatedVersionKey = @"iRateRatedVersionChecked";
static NSString *const iRateDeclinedVersionKey = @"iRateDeclinedVersion";
static NSString *const iRateLastRemindedKey = @"iRateLastReminded";
static NSString *const iRateLastVersionUsedKey = @"iRateLastVersionUsed";
static NSString *const iRateFirstUsedKey = @"iRateFirstUsed";
static NSString *const iRateUseCountKey = @"iRateUseCount";
static NSString *const iRateEventCountKey = @"iRateEventCount";

static NSString *const iRateMacAppStoreBundleID = @"com.apple.appstore";

//note, these don't link directly to the review page - there doesn't seem to be a way to do that
static NSString *const iRateiOSAppStoreURLFormat = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%i";
static NSString *const iRateMacAppStoreURLFormat = @"macappstore://itunes.apple.com/app/id%i";


#define SECONDS_IN_A_DAY 86400.0
#define MAC_APP_STORE_REFRESH_DELAY 5.0


#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
@interface iRate() <UIAlertViewDelegate>
#else
@interface iRate()
#endif

@property (nonatomic, strong) id visibleAlert;

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
@synthesize promptAtLaunch;
@synthesize debug;
@synthesize delegate;
@synthesize visibleAlert;

#pragma mark -
#pragma mark Lifecycle methods

+ (iRate *)sharedInstance
{
    static iRate *sharedInstance = nil;
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
        //localised application name and version
        self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        self.applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        if ([applicationName length] == 0)
        {
            self.applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
        }
        
        //usage settings - these have sensible defaults
        promptAtLaunch = YES;
        usesUntilPrompt = 10;
        eventsUntilPrompt = 10;
        daysUntilPrompt = 10.0f;
        remindPeriod = 1.0f;
        
        //message text, you may wish to customise these, e.g. for localisation
        self.messageTitle = nil; //set lazily so that appname can be included
        self.message = nil; //set lazily so that appname can be included
        self.cancelButtonLabel = NSLocalizedStringFromTable(@"No, Thanks", @"iRate", @"Button in prompting message stating that they would not like to rate the app. Pressing this button will dismiss the prompt.") ;
        self.remindButtonLabel = NSLocalizedStringFromTable(@"Remind Me Later", @"iRate", @"Button in prompting message stating that they would like to be reminded to rate the app. Pressing this button will dismiss the prompt.") ;
        self.rateButtonLabel = NSLocalizedStringFromTable(@"Rate It Now", @"iRate", @"Button in prompting message stating that they would like to rate the app. Pressing this button will take the user to the app store.") ;
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
    
    
    NSString *formatString = NSLocalizedStringFromTable(@"If you enjoy using %@, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!", @"iRate", @"This is the default message that is show to prompt the user asking them to rate the app");
    
    return [NSString stringWithFormat:formatString, applicationName];
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
    
    AH_RELEASE(applicationName);
    AH_RELEASE(applicationVersion);
    AH_RELEASE(messageTitle);
    AH_RELEASE(message);
    AH_RELEASE(cancelButtonLabel);
    AH_RELEASE(remindButtonLabel);
    AH_RELEASE(rateButtonLabel);
    AH_RELEASE(ratingsURL);
    AH_RELEASE(visibleAlert);
    AH_SUPER_DEALLOC;
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
    //debug mode?
    if (debug)
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
    if (!visibleAlert)
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
        
        self.visibleAlert = alert;
        [visibleAlert show];
        AH_RELEASE(alert);

#else

        //only show when main window is available
        if (![[NSApplication sharedApplication] mainWindow])
        {
            [self performSelector:@selector(promptForRating) withObject:nil afterDelay:0.5];
            return;
        }
        
        self.visibleAlert = [NSAlert alertWithMessageText:self.messageTitle
                                            defaultButton:rateButtonLabel
                                          alternateButton:cancelButtonLabel
                                              otherButton:nil
                                informativeTextWithFormat:self.message];    
        
        if (remindButtonLabel)
        {
            [visibleAlert addButtonWithTitle:remindButtonLabel];
        }
        
        [visibleAlert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow]
                                 modalDelegate:self
                                didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                   contextInfo:nil];

#endif
        
    }
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
    if ([delegate respondsToSelector:@selector(iRateShouldPromptForRating)])
    {
        if (![delegate iRateShouldPromptForRating])
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
    if ([delegate respondsToSelector:@selector(iRateCouldNotConnectToAppStore:)])
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

        //inform about app update
        if ([delegate respondsToSelector:@selector(iRateDidDetectAppUpdate)])
        {
            [delegate iRateDidDetectAppUpdate];
        }        
    }
    
    [self incrementUseCount];
    if (promptAtLaunch && [self shouldPromptForRating])
    {
        [self promptIfNetworkAvailable];
    }
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        [self incrementUseCount];
        if (promptAtLaunch && [self shouldPromptForRating])
        {
            [self promptIfNetworkAvailable];
        }
    }
}

#endif

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
        //log event
        if ([delegate respondsToSelector:@selector(iRateUserDidDeclineToRateApp)])
        {
            [delegate iRateUserDidDeclineToRateApp];
        }
        
        //ignore this version
        self.declinedThisVersion = YES;
    }
    else if (buttonIndex == 2)
    {
        //log event
        if ([delegate respondsToSelector:@selector(iRateUserDidRequestReminderToRateApp)])
        {
            [delegate iRateUserDidRequestReminderToRateApp];
        }
        
        //remind later
        self.lastReminded = [NSDate date];
    }
    else
    {
        //log event
        if ([delegate respondsToSelector:@selector(iRateUserDidAttemptToRateApp)])
        {
            [delegate iRateUserDidAttemptToRateApp];
        }
        
        //mark as rated
        self.ratedThisVersion = YES;
        
        //go to ratings page
        [self openRatingsPageInAppStore];
    }
    
    //release alert
    self.visibleAlert = nil;
}

#else

- (void)openAppPageWhenAppStoreLaunched
{
    //check if app store is running
    ProcessSerialNumber psn = { kNoProcess, kNoProcess };
    while (GetNextProcess(&psn) == noErr)
    {
        CFDictionaryRef cfDict = ProcessInformationCopyDictionary(&psn,  kProcessDictionaryIncludeAllInformationMask);
        NSString *bundleID = [(__bridge NSDictionary *)cfDict objectForKey:(NSString *)kCFBundleIdentifierKey];
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
    [self performSelector:@selector(openAppPageWhenAppStoreLaunched) withObject:nil afterDelay:0.0];
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
            //log event
            if ([delegate respondsToSelector:@selector(iRateUserDidDeclineToRateApp)])
            {
                [delegate iRateUserDidDeclineToRateApp];
            }
            
            //ignore this version
            self.declinedThisVersion = YES;
            break;
        }
        case NSAlertDefaultReturn:
        {
            //log event
            if ([delegate respondsToSelector:@selector(iRateUserDidAttemptToRateApp)])
            {
                [delegate iRateUserDidAttemptToRateApp];
            }
            
            //mark as rated
            self.ratedThisVersion = YES;
            
            //launch mac app store
            [self openRatingsPageInAppStore];
            break;
        }
        default:
        {
            //log event
            if ([delegate respondsToSelector:@selector(iRateUserDidRequestReminderToRateApp)])
            {
                [delegate iRateUserDidRequestReminderToRateApp];
            }
            
            //remind later
            self.lastReminded = [NSDate date];
        }
    }
    
    //release alert
    self.visibleAlert = nil;
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