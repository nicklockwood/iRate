//
//  iRate.m
//
//  Version 1.4.3
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


NSString *const iRateAppStoreGenreGame = @"Games";

static NSString *const iRateRatedVersionKey = @"iRateRatedVersionChecked";
static NSString *const iRateDeclinedVersionKey = @"iRateDeclinedVersion";
static NSString *const iRateLastRemindedKey = @"iRateLastReminded";
static NSString *const iRateLastVersionUsedKey = @"iRateLastVersionUsed";
static NSString *const iRateFirstUsedKey = @"iRateFirstUsed";
static NSString *const iRateUseCountKey = @"iRateUseCount";
static NSString *const iRateEventCountKey = @"iRateEventCount";

static NSString *const iRateMacAppStoreBundleID = @"com.apple.appstore";
static NSString *const iRateAppLookupURLFormat = @"http://itunes.apple.com/lookup?country=%@";

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
@synthesize appStoreGenre;
@synthesize appStoreCountry;
@synthesize applicationName;
@synthesize applicationVersion;
@synthesize applicationBundleID;
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
@synthesize onlyPromptIfLatestVersion;
@synthesize promptAtLaunch;
@synthesize debug;
@synthesize delegate;
@synthesize visibleAlert;

#pragma mark -
#pragma mark Lifecycle methods

+ (void)load
{
    @autoreleasepool
    {
        //initialise iRate
        [iRate sharedInstance];
    }
}

+ (iRate *)sharedInstance
{
    static iRate *sharedInstance = nil;
    if (sharedInstance == nil)
    {
        sharedInstance = [[iRate alloc] init];
    }
    return sharedInstance;
}

- (NSString *)localizedStringForKey:(NSString *)key
{
    static NSBundle *bundle = nil;
    if (bundle == nil)
    {
        //get localisation bundle
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"iRate" ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:bundlePath] ?: [NSBundle mainBundle];
        
        //get correct lproj folder as this doesn't always happen automatically
        for (NSString *language in [NSLocale preferredLanguages])
        {
            if ([[bundle localizations] containsObject:language])
            {
                bundlePath = [bundle pathForResource:language ofType:@"lproj"];
                bundle = [NSBundle bundleWithPath:bundlePath];
                break;
            }
        }
        
        //retain bundle
        bundle = AH_RETAIN(bundle);
    }
    
    //return localised string
    return [bundle localizedStringForKey:key value:nil table:nil];
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didRotate)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
#else
        //register for mac application events
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationLaunched:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
#endif
        
        //get country
        self.appStoreCountry = [(NSLocale *)[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        
        //application version (use short version preferentially)
        self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if ([applicationVersion length] == 0)
        {
            self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        }
        
        //localised application name
        self.applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        if ([applicationName length] == 0)
        {
            self.applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
        }
        
        //bundle id
        self.applicationBundleID = [[NSBundle mainBundle] bundleIdentifier];
        
        //usage settings - these have sensible defaults
        onlyPromptIfLatestVersion = YES;
        promptAtLaunch = YES;
        usesUntilPrompt = 10;
        eventsUntilPrompt = 10;
        daysUntilPrompt = 10.0f;
        remindPeriod = 1.0f;
        
        //message text, you may wish to customise these, e.g. for localisation
        self.messageTitle = nil; //set lazily so that appname can be included
        self.message = nil; //set lazily so that appname can be included
        self.cancelButtonLabel = [self localizedStringForKey:@"No, Thanks"];
        self.remindButtonLabel = [self localizedStringForKey:@"Remind Me Later"];
        self.rateButtonLabel = [self localizedStringForKey:@"Rate It Now"];
    }
    return self;
}

- (id<iRateDelegate>)delegate
{
    if (delegate == nil)
    {
        
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
        
        delegate = (id<iRateDelegate>)[[UIApplication sharedApplication] delegate];
#else
        delegate = (id<iRateDelegate>)[[NSApplication sharedApplication] delegate];
#endif
        
    }
    return delegate;
}

- (NSString *)messageTitle
{
    if (messageTitle)
    {
        return messageTitle;
    }
    return [NSString stringWithFormat:[self localizedStringForKey:@"Rate %@"], applicationName];
}

- (NSString *)message
{
    if (message)
    {
        return message;
    }
    if ([appStoreGenre isEqualToString:iRateAppStoreGenreGame])
    {
         return [NSString stringWithFormat:[self localizedStringForKey:@"If you enjoy playing %@, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!"], applicationName];
    }
    else
    {
        return [NSString stringWithFormat:[self localizedStringForKey:@"If you enjoy using %@, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!"], applicationName];

    }   
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
    
    AH_RELEASE(appStoreGenre);
    AH_RELEASE(appStoreCountry);
    AH_RELEASE(applicationName);
    AH_RELEASE(applicationVersion);
    AH_RELEASE(applicationBundleID);
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

- (NSString *)valueForKey:(NSString *)key inJSON:(NSString *)json
{
    NSRange keyRange = [json rangeOfString:[NSString stringWithFormat:@"\"%@\"", key]];
    if (keyRange.location != NSNotFound)
    {
        NSInteger start = keyRange.location + keyRange.length;
        NSRange valueStart = [json rangeOfString:@":" options:0 range:NSMakeRange(start, [json length] - start)];
        if (valueStart.location != NSNotFound)
        {
            start = valueStart.location + 1;
            NSRange valueEnd = [json rangeOfString:@"," options:0 range:NSMakeRange(start, [json length] - start)];
            if (valueEnd.location != NSNotFound)
            {
                NSString *value = [json substringWithRange:NSMakeRange(start, valueEnd.location - start)];
                value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                while ([value hasPrefix:@"\""] && ![value hasSuffix:@"\""])
                {
                    if (valueEnd.location == NSNotFound)
                    {
                        break;
                    }
                    NSInteger newStart = valueEnd.location + 1;
                    valueEnd = [json rangeOfString:@"," options:0 range:NSMakeRange(newStart, [json length] - newStart)];
                    value = [json substringWithRange:NSMakeRange(start, valueEnd.location - start)];
                    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                
                value = [value stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
                value = [value stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
                value = [value stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
                value = [value stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
                value = [value stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
                value = [value stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
                value = [value stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"];
                value = [value stringByReplacingOccurrencesOfString:@"\\f" withString:@"\f"];
                value = [value stringByReplacingOccurrencesOfString:@"\\b" withString:@"\f"];
                
                while (YES)
                {
                    NSRange unicode = [value rangeOfString:@"\\u"];
                    if (unicode.location == NSNotFound)
                    {
                        break;
                    }
                    
                    uint32_t c = 0;
                    NSString *hex = [value substringWithRange:NSMakeRange(unicode.location + 2, 4)];
                    NSScanner *scanner = [NSScanner scannerWithString:hex];
                    [scanner scanHexInt:&c];
                    
                    if (c <= 0xffff)
                    {
                        value = [value stringByReplacingCharactersInRange:NSMakeRange(unicode.location, 6) withString:[NSString stringWithFormat:@"%C", (unichar)c]];
                    }
                    else
                    {
                        //convert character to surrogate pair
                        uint16_t x = (uint16_t)c;
                        uint16_t u = (c >> 16) & ((1 << 5) - 1);
                        uint16_t w = (uint16_t)u - 1;
                        unichar high = 0xd800 | (w << 6) | x >> 10;
                        unichar low = (uint16_t)(0xdc00 | (x & ((1 << 10) - 1)));
                        
                        value = [value stringByReplacingCharactersInRange:NSMakeRange(unicode.location, 6) withString:[NSString stringWithFormat:@"%C%C", high, low]];
                    }
                }
                return value;
            }
        }
    }
    return nil;
}

- (void)setAppStoreIDOnMainThread:(NSString *)appStoreIDString
{
    self.appStoreID = [appStoreIDString longLongValue];
}

- (void)connectionSucceeded
{
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

- (void)connectionError:(NSError *)error
{
    //could not connect
    if ([delegate respondsToSelector:@selector(iRateCouldNotConnectToAppStore:)])
    {
        [delegate iRateCouldNotConnectToAppStore:error];
    }
}

- (void)checkForConnectivityInBackground
{
    @synchronized (self)
    {
        @autoreleasepool
        {
            //first check iTunes
            NSString *iTunesServiceURL = [NSString stringWithFormat:iRateAppLookupURLFormat, appStoreCountry];
            if (appStoreID)
            {
                iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"&id=%i", appStoreID];
            }
            else 
            {
                iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"&bundleId=%@", applicationBundleID];
            }
            NSError *error = nil;
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:iTunesServiceURL] options:NSDataReadingUncached error:&error];
            if (data)
            {
                //convert to string
                NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                //check bundle ID matches
                NSString *bundleID = [self valueForKey:@"bundleId" inJSON:json];
                if ((bundleID && [bundleID isEqualToString:applicationBundleID]) || debug)
                {
                    //get genre  
                    if (!appStoreGenre)
                    {
                        [self performSelectorOnMainThread:@selector(setAppStoreGenre:) withObject:[self valueForKey:@"primaryGenreName" inJSON:json] waitUntilDone:YES];
                    }
                    
                    //get app id
                    if (!appStoreID)
                    {
                        NSString *appStoreIDString = [self valueForKey:@"trackId" inJSON:json];
                        [self performSelectorOnMainThread:@selector(setAppStoreIDOnMainThread:) withObject:appStoreIDString waitUntilDone:YES];
                    }
                    
                    //check version
                    if (onlyPromptIfLatestVersion && !debug)
                    {
                        NSString *latestVersion = [self valueForKey:@"version" inJSON:json];
                        if ([latestVersion compare:applicationVersion options:NSNumericSearch] == NSOrderedDescending)
                        {
                            error = [NSError errorWithDomain:@"iRate" code:1 userInfo:[NSDictionary dictionaryWithObject:@"Installed app is not the latest version available" forKey:NSLocalizedDescriptionKey]];
                        }
                    }
                }
                else
                {
                    error = [NSError errorWithDomain:@"iRate" code:2 userInfo:[NSDictionary dictionaryWithObject:@"Service bundleID and applicationBundleID did not match" forKey:NSLocalizedDescriptionKey]];
                }
                
                //release json
                AH_RELEASE(json);
            }
            
            if (error)
            {
                [self performSelectorOnMainThread:@selector(connectionError:) withObject:error waitUntilDone:YES];
            }
            else if (appStoreID || debug)
            {
                //show prompt
                [self performSelectorOnMainThread:@selector(connectionSucceeded) withObject:nil waitUntilDone:YES];
            }
        }
    }
}

- (void)promptIfNetworkAvailable
{
    [self performSelectorInBackground:@selector(checkForConnectivityInBackground) withObject:nil];
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
                                informativeTextWithFormat:@"%@", self.message];
        
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
#pragma mark UIAlertView methods

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

- (void)openRatingsPageInAppStore
{
    [[UIApplication sharedApplication] openURL:self.ratingsURL];
}

- (void)resizeAlertView:(UIAlertView *)alertView
{
    CGFloat offset = 0.0f;
    for (UIView *view in alertView.subviews)
    {
        CGRect frame = view.frame;
        if ([view isKindOfClass:[UILabel class]])
        {
            UILabel *label = (UILabel *)view;
            if ([label.text isEqualToString:alertView.message])
            {
                label.alpha = 1.0f;
                label.lineBreakMode = UILineBreakModeWordWrap;
                label.numberOfLines = 0;
                [label sizeToFit];
                offset = label.frame.size.height - frame.size.height;
                frame.size.height = label.frame.size.height;
            }
        }
        else if ([view isKindOfClass:[UITextView class]])
        {
            view.alpha = 0.0f;
        }
        else if ([view isKindOfClass:[UIControl class]])
        {
            frame.origin.y += offset;
        }
        view.frame = frame;
    }
    CGRect frame = alertView.frame;
    frame.origin.y -= roundf(offset/2.0f);
    frame.size.height += offset;
    alertView.frame = frame;
}

- (void)didRotate
{
    [self performSelectorOnMainThread:@selector(resizeAlertView:) withObject:visibleAlert waitUntilDone:NO];
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
    [self resizeAlertView:alertView];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    //consider cancel button presence
    if (alertView.cancelButtonIndex == -1) {
        ++buttonIndex;
    }

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
