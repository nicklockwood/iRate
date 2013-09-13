//
//  iRate.m
//
//  Version 1.8 beta 4
//
//  Created by Nick Lockwood on 26/01/2011.
//  Copyright 2011 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
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


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


NSUInteger const iRateAppStoreGameGenreID = 6014;
NSString *const iRateErrorDomain = @"iRateErrorDomain";


static NSString *const iRateAppStoreIDKey = @"iRateAppStoreID";
static NSString *const iRateRatedVersionKey = @"iRateRatedVersionChecked";
static NSString *const iRateDeclinedVersionKey = @"iRateDeclinedVersion";
static NSString *const iRateLastRemindedKey = @"iRateLastReminded";
static NSString *const iRateLastVersionUsedKey = @"iRateLastVersionUsed";
static NSString *const iRateFirstUsedKey = @"iRateFirstUsed";
static NSString *const iRateUseCountKey = @"iRateUseCount";
static NSString *const iRateEventCountKey = @"iRateEventCount";

static NSString *const iRateMacAppStoreBundleID = @"com.apple.appstore";
static NSString *const iRateAppLookupURLFormat = @"http://itunes.apple.com/%@/lookup";

static NSString *const iRateiOSAppStoreURLFormat = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@";
static NSString *const iRateiOS7AppStoreURLFormat = @"itms-apps://itunes.apple.com/app/id%@";
static NSString *const iRateMacAppStoreURLFormat = @"macappstore://itunes.apple.com/app/id%@";


#define SECONDS_IN_A_DAY 86400.0
#define SECONDS_IN_A_WEEK 604800.0
#define MAC_APP_STORE_REFRESH_DELAY 5.0
#define REQUEST_TIMEOUT 60.0


@interface iRate()

@property (nonatomic, strong) id visibleAlert;
@property (nonatomic, assign) int previousOrientation;
@property (nonatomic, assign) BOOL checkingForPrompt;

@end


@implementation iRate

+ (void)load
{
    [self performSelectorOnMainThread:@selector(sharedInstance) withObject:nil waitUntilDone:NO];
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

- (NSString *)localizedStringForKey:(NSString *)key withDefault:(NSString *)defaultString
{
    static NSBundle *bundle = nil;
    if (bundle == nil)
    {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"iRate" ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:bundlePath] ?: [NSBundle mainBundle];
        if (self.useAllAvailableLanguages)
        {
            for (NSString *language in [NSLocale preferredLanguages])
            {
                if ([[bundle localizations] containsObject:language])
                {
                    bundlePath = [bundle pathForResource:language ofType:@"lproj"];
                    bundle = [NSBundle bundleWithPath:bundlePath];
                    break;
                }
            }
        }
    }
    defaultString = [bundle localizedStringForKey:key value:defaultString table:nil];
    return [[NSBundle mainBundle] localizedStringForKey:key value:defaultString table:nil];
}

- (iRate *)init
{
    if ((self = [super init]))
    {
        
#if TARGET_OS_IPHONE
        
        //register for iphone application events
        if (&UIApplicationWillEnterForegroundNotification)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationWillEnterForeground)
                                                         name:UIApplicationWillEnterForegroundNotification
                                                       object:nil];
        }
        
        self.previousOrientation = [UIApplication sharedApplication].statusBarOrientation;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willRotate)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        
#endif
        
        //get country
        self.appStoreCountry = [(NSLocale *)[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        
        //application version (use short version preferentially)
        self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if ([self.applicationVersion length] == 0)
        {
            self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        }
        
        //localised application name
        self.applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        if ([self.applicationName length] == 0)
        {
            self.applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
        }
        
        //bundle id
        self.applicationBundleID = [[NSBundle mainBundle] bundleIdentifier];
        
        //default settings
        self.useAllAvailableLanguages = YES;
        self.onlyPromptIfLatestVersion = YES;
        self.onlyPromptIfMainWindowIsAvailable = YES;
        self.promptAgainForEachNewVersion = YES;
        self.promptAtLaunch = YES;
        self.usesUntilPrompt = 10;
        self.eventsUntilPrompt = 10;
        self.daysUntilPrompt = 10.0f;
        self.usesPerWeekForPrompt = 0.0f;
        self.remindPeriod = 1.0f;
        self.verboseLogging = NO;
        self.previewMode = NO;
        
#if DEBUG
        
        //enable verbose logging in debug mode
        self.verboseLogging = YES;
        
#endif
        
        //app launched
        [self performSelectorOnMainThread:@selector(applicationLaunched) withObject:nil waitUntilDone:NO];
    }
    return self;
}

- (id<iRateDelegate>)delegate
{
    if (_delegate == nil)
    {
        
#if TARGET_OS_IPHONE
#define APP_CLASS UIApplication      
#else
#define APP_CLASS NSApplication  
#endif
        
        _delegate = (id<iRateDelegate>)[[APP_CLASS sharedApplication] delegate];
    }
    return _delegate;
}

- (NSString *)messageTitle
{
    return [_messageTitle ?: [self localizedStringForKey:iRateMessageTitleKey withDefault:@"Rate %@"] stringByReplacingOccurrencesOfString:@"%@" withString:self.applicationName];
}

- (NSString *)message
{
    NSString *message = _message;
    if (!message)
    {
        message = (self.appStoreGenreID == iRateAppStoreGameGenreID)? [self localizedStringForKey:iRateGameMessageKey withDefault:@"If you enjoy playing %@, would you mind taking a moment to rate it? It won’t take more than a minute. Thanks for your support!"]: [self localizedStringForKey:iRateAppMessageKey withDefault:@"If you enjoy using %@, would you mind taking a moment to rate it? It won’t take more than a minute. Thanks for your support!"];
    }
    return [message stringByReplacingOccurrencesOfString:@"%@" withString:self.applicationName];
}

- (NSString *)cancelButtonLabel
{
    return _cancelButtonLabel ?: [self localizedStringForKey:iRateCancelButtonKey withDefault:@"No, Thanks"];
}

- (NSString *)rateButtonLabel
{
    return _rateButtonLabel ?: [self localizedStringForKey:iRateRateButtonKey withDefault:@"Rate It Now"];
}

- (NSString *)remindButtonLabel
{
    return _remindButtonLabel ?: [self localizedStringForKey:iRateRemindButtonKey withDefault:@"Remind Me Later"];
}

- (NSURL *)ratingsURL
{
    if (_ratingsURL)
    {
        return _ratingsURL;
    }
    
    if (!self.appStoreID)
    {
        NSLog(@"iRate could not find the App Store ID for this application. If the application is not intended for App Store release then you must specify a custom ratingsURL.");
    }
    
#if TARGET_OS_IPHONE
    
    return [NSURL URLWithString:[NSString stringWithFormat:([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f)? iRateiOS7AppStoreURLFormat: iRateiOSAppStoreURLFormat, @(self.appStoreID)]];
    
#else
    
    return [NSURL URLWithString:[NSString stringWithFormat:iRateMacAppStoreURLFormat, @(self.appStoreID)]];
    
#endif
    
}

- (NSUInteger)appStoreID
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:iRateAppStoreIDKey] unsignedIntegerValue];
}

- (void)setAppStoreID:(NSUInteger)appStoreID
{
    [[NSUserDefaults standardUserDefaults] setInteger:appStoreID forKey:iRateAppStoreIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
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

- (NSUInteger)eventCount
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:iRateEventCountKey];
}

- (void)setEventCount:(NSUInteger)count
{
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:iRateEventCountKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (float)usesPerWeek
{
    return (float)self.usesCount / ([[NSDate date] timeIntervalSinceDate:self.firstUsed] / SECONDS_IN_A_WEEK);
}

- (BOOL)declinedThisVersion
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:iRateDeclinedVersionKey] isEqualToString:self.applicationVersion];
}

- (void)setDeclinedThisVersion:(BOOL)declined
{
    [[NSUserDefaults standardUserDefaults] setObject:(declined? self.applicationVersion: nil) forKey:iRateDeclinedVersionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)declinedAnyVersion
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:iRateDeclinedVersionKey] length];
}

- (BOOL)ratedThisVersion
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:iRateRatedVersionKey] isEqualToString:self.applicationVersion];
}

- (void)setRatedThisVersion:(BOOL)rated
{
    [[NSUserDefaults standardUserDefaults] setObject:(rated? self.applicationVersion: nil) forKey:iRateRatedVersionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)ratedAnyVersion
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:iRateRatedVersionKey] length];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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
    //preview mode?
    if (self.previewMode)
    {
        NSLog(@"iRate preview mode is enabled - make sure you disable this for release");
        return YES;
    }
    
    //check if we've rated this version
    else if (self.ratedThisVersion)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the user has already rated this version");
        }
        return NO;
    }
    
    //check if we've rated any version
    else if (!self.promptAgainForEachNewVersion && self.ratedAnyVersion)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the user has already rated this app, and promptAgainForEachNewVersion is disabled");
        }
        return NO;
    }
    
    //check if we've declined to rate this version
    else if (self.declinedThisVersion)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the user has declined to rate this version");
        }
        return NO;
    }
    
    //check for first launch
    else if ((self.daysUntilPrompt > 0.0f || self.usesPerWeekForPrompt) && self.firstUsed == nil)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because this is the first time the app has been launched");
        }
        return NO;
    }
    
    //check how long we've been using this version
    else if ([[NSDate date] timeIntervalSinceDate:self.firstUsed] < self.daysUntilPrompt * SECONDS_IN_A_DAY)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the app was first used less than %g days ago", self.daysUntilPrompt);
        }
        return NO;
    }
    
    //check how many times we've used it and the number of significant events
    else if (self.usesCount < self.usesUntilPrompt && self.eventCount < self.eventsUntilPrompt)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the app has only been used %@ times and only %@ events have been logged", @(self.usesCount), @(self.eventCount));
        }
        return NO;
    }
    
    //check if usage frequency is high enough
    else if (self.usesPerWeek < self.usesPerWeekForPrompt)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the app has only been used %g times per week on average since it was installed", self.usesPerWeek);
        }
        return NO;
    }

    //check if within the reminder period
    else if (self.lastReminded != nil && [[NSDate date] timeIntervalSinceDate:self.lastReminded] < self.remindPeriod * SECONDS_IN_A_DAY)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate did not prompt for rating because the user last asked to be reminded less than %g days ago", self.remindPeriod);
        }
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
    self.appStoreID = (NSUInteger)[appStoreIDString longLongValue];
}

- (void)connectionSucceeded
{
    if (self.checkingForPrompt)
    {
        //no longer checking
        self.checkingForPrompt = NO;
        
        //confirm with delegate
        if ([self.delegate respondsToSelector:@selector(iRateShouldPromptForRating)])
        {
            if (![self.delegate iRateShouldPromptForRating])
            {
                if (self.verboseLogging)
                {
                    NSLog(@"iRate did not display the rating prompt because the iRateShouldPromptForRating delegate method returned NO");
                }
                return;
            }
        }
        
        //prompt user
        [self promptForRating];
    }
}

- (void)connectionError:(NSError *)error
{
    //no longer checking
    self.checkingForPrompt = NO;
    
    //log the error
    if (error)
    {
        NSLog(@"iRate rating process failed because: %@", [error localizedDescription]);
    }
    else
    {
        NSLog(@"iRate rating process failed because an unknown error occured");
    }
    
    //could not connect
    if ([self.delegate respondsToSelector:@selector(iRateCouldNotConnectToAppStore:)])
    {
        [self.delegate iRateCouldNotConnectToAppStore:error];
    }
}

- (void)checkForConnectivityInBackground
{
    @synchronized (self)
    {
        @autoreleasepool
        {
            //first check iTunes
            NSString *iTunesServiceURL = [NSString stringWithFormat:iRateAppLookupURLFormat, self.appStoreCountry];
            if (self.appStoreID)
            {
                iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"?id=%@", @(self.appStoreID)];
            }
            else 
            {
                iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"?bundleId=%@", self.applicationBundleID];
            }
            
            if (self.verboseLogging)
            {
                NSLog(@"iRate is checking %@ to retrieve the App Store details...", iTunesServiceURL);
            }
            
            NSError *error = nil;
            NSURLResponse *response = nil;
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:iTunesServiceURL] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:REQUEST_TIMEOUT];
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            if (data && statusCode == 200)
            {
                //in case error is garbage...
                error = nil;
                
                //convert to string
                NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                //check bundle ID matches
                NSString *bundleID = [self valueForKey:@"bundleId" inJSON:json];
                if (bundleID)
                {
                    if ([bundleID isEqualToString:self.applicationBundleID])
                    {
                        //get genre
                        if (self.appStoreGenreID == 0)
                        {
                            self.appStoreGenreID = [[self valueForKey:@"primaryGenreId" inJSON:json] integerValue];
                        }
                        
                        //get app id
                        if (!self.appStoreID)
                        {
                            NSString *appStoreIDString = [self valueForKey:@"trackId" inJSON:json];
                            [self performSelectorOnMainThread:@selector(setAppStoreIDOnMainThread:) withObject:appStoreIDString waitUntilDone:YES];
                            
                            if (self.verboseLogging)
                            {
                                NSLog(@"iRate found the app on iTunes. The App Store ID is %@", appStoreIDString);
                            }
                        }
                        
                        //check version
                        if (self.onlyPromptIfLatestVersion && !self.previewMode)
                        {
                            NSString *latestVersion = [self valueForKey:@"version" inJSON:json];
                            if ([latestVersion compare:self.applicationVersion options:NSNumericSearch] == NSOrderedDescending)
                            {
                                if (self.verboseLogging)
                                {
                                    NSLog(@"iRate found that the installed application version (%@) is not the latest version on the App Store, which is %@",
                                          self.applicationVersion, latestVersion);
                                }
                                
                                error = [NSError errorWithDomain:iRateErrorDomain code:iRateErrorApplicationIsNotLatestVersion userInfo:@{NSLocalizedDescriptionKey: @"Installed app is not the latest version available"}];
                            }
                        }
                    }
                    else
                    {
                        if (self.verboseLogging)
                        {
                            NSLog(@"iRate found that the application bundle ID (%@) does not match the bundle ID of the app found on iTunes (%@) with the specified App Store ID (%@)", self.applicationBundleID, bundleID, @(self.appStoreID));
                        }
                        
                        error = [NSError errorWithDomain:iRateErrorDomain code:iRateErrorBundleIdDoesNotMatchAppStore userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Application bundle ID does not match expected value of %@", bundleID]}];
                    }
                }
                else if (self.appStoreID || !self.ratingsURL)
                {
                    if (self.verboseLogging)
                    {
                        NSLog(@"iRate could not find this application on iTunes. If your app is not intended for App Store release then you must specify a custom ratingsURL. If this is the first release of your application then it's not a problem that it cannot be found on the store yet");
                    }
                    
                    error = [NSError errorWithDomain:iRateErrorDomain
                                                code:iRateErrorApplicationNotFoundOnAppStore
                                            userInfo:@{NSLocalizedDescriptionKey: @"The application could not be found on the App Store."}];
                }
                else if (!self.appStoreID && self.verboseLogging)
                {
                    NSLog(@"iRate could not find your app on iTunes. If your app is not yet on the store or is not intended for App Store release then don't worry about this");
                }
            }
            else if (statusCode >= 400)
            {
                //http error
                NSString *message = [NSString stringWithFormat:@"The server returned a %@ error", @(statusCode)];
                error = [NSError errorWithDomain:@"HTTPResponseErrorDomain" code:statusCode userInfo:@{NSLocalizedDescriptionKey: message}];
            }
            
            //handle errors
            if (error && !(error.code == EPERM && [error.domain isEqualToString:NSPOSIXErrorDomain] && self.appStoreID))
            {
                [self performSelectorOnMainThread:@selector(connectionError:) withObject:error waitUntilDone:YES];
            }
            else if (self.appStoreID || self.previewMode)
            {
                //show prompt
                [self performSelectorOnMainThread:@selector(connectionSucceeded) withObject:nil waitUntilDone:YES];
            }
        }
    }
}

- (void)promptIfNetworkAvailable
{
    if (!self.checkingForPrompt)
    {
        self.checkingForPrompt = YES;
        [self performSelectorInBackground:@selector(checkForConnectivityInBackground) withObject:nil];
    }
}

- (void)promptForRating
{
    if (!self.visibleAlert)
    {
    
#if TARGET_OS_IPHONE
    
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.messageTitle
                                                        message:self.message
                                                       delegate:(id<UIAlertViewDelegate>)self
                                              cancelButtonTitle:[self.cancelButtonLabel length] ? self.cancelButtonLabel: nil
                                              otherButtonTitles:self.rateButtonLabel, nil];
        if ([self.remindButtonLabel length])
        {
            [alert addButtonWithTitle:self.remindButtonLabel];
        }
        
        self.visibleAlert = alert;
        [self.visibleAlert show];
#else

        //only show when main window is available
        if (self.onlyPromptIfMainWindowIsAvailable && ![[NSApplication sharedApplication] mainWindow])
        {
            [self performSelector:@selector(promptForRating) withObject:nil afterDelay:0.5];
            return;
        }
        
        self.visibleAlert = [NSAlert alertWithMessageText:self.messageTitle
                                            defaultButton:self.rateButtonLabel
                                          alternateButton:self.cancelButtonLabel
                                              otherButton:nil
                                informativeTextWithFormat:@"%@", self.message];
        
        if ([self.remindButtonLabel length])
        {
            [self.visibleAlert addButtonWithTitle:self.remindButtonLabel];
        }
        
        [self.visibleAlert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow]
                                      modalDelegate:self
                                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                                        contextInfo:nil];

#endif

        //inform about prompt
        if ([self.delegate respondsToSelector:@selector(iRateDidPromptForRating)])
        {
            [self.delegate iRateDidPromptForRating];
        }
    }
}

- (void)applicationLaunched
{
    //check if this is a new version
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![[defaults objectForKey:iRateLastVersionUsedKey] isEqualToString:self.applicationVersion])
    {
        //reset counts
        [defaults setObject:self.applicationVersion forKey:iRateLastVersionUsedKey];
        [defaults setObject:[NSDate date] forKey:iRateFirstUsedKey];
        [defaults setInteger:0 forKey:iRateUseCountKey];
        [defaults setInteger:0 forKey:iRateEventCountKey];
        [defaults setObject:nil forKey:iRateLastRemindedKey];
        [defaults synchronize];

        //inform about app update
        if ([self.delegate respondsToSelector:@selector(iRateDidDetectAppUpdate)])
        {
            [self.delegate iRateDidDetectAppUpdate];
        }        
    }
    
    [self incrementUseCount];
    if (self.promptAtLaunch && [self shouldPromptForRating])
    {
        [self promptIfNetworkAvailable];
    }
}

#if TARGET_OS_IPHONE

- (void)applicationWillEnterForeground
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        [self incrementUseCount];
        if (self.promptAtLaunch && [self shouldPromptForRating])
        {
            [self promptIfNetworkAvailable];
        }
    }
}

- (BOOL)openRatingsPageInAppStore
{
    if (!_ratingsURL && !self.appStoreID)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate was unable to open the App Store because the app store ID is not set.");
        }
        return NO;
    }
    
#if IRATE_USE_STOREKIT
    
    if (!_ratingsURL && [SKStoreProductViewController class])
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate will attempt to open the StoreKit in-app product page using the following app store ID: %@", @(self.appStoreID));
        }
        
        //create store view controller
        SKStoreProductViewController *productController = [[SKStoreProductViewController alloc] init];
        productController.delegate = (id<SKStoreProductViewControllerDelegate>)self;
        
        //load product details
        NSDictionary *productParameters = @{SKStoreProductParameterITunesItemIdentifier: [@(self.appStoreID) description]};
        [productController loadProductWithParameters:productParameters completionBlock:^(BOOL result, NSError *error) {
            
            if (!result)
            {
                //log the error
                if (error)
                {
                    NSLog(@"iRate rating process failed because: %@", [error localizedDescription]);
                }
                else
                {
                    NSLog(@"iRate rating process failed because an unknown error occured");
                }
                
                self.ratedThisVersion = NO;
                if ([self.delegate respondsToSelector:@selector(iRateCouldNotConnectToAppStore:)])
                {
                    [self.delegate iRateCouldNotConnectToAppStore:error];
                }
            }
        }];
        
        //get root view controller
        UIWindow *window = [[UIApplication sharedApplication] delegate].window;
        UIViewController *rootViewController = window.rootViewController;
        if (!rootViewController)
        {
            if (self.verboseLogging)
            {
                NSLog(@"iRate couldn't find root view controller from which to display StoreKit product page");
            }
        }
        else
        {
            while (rootViewController.presentedViewController)
            {
                rootViewController = rootViewController.presentedViewController;
            }
            
            //present product view controller
            [rootViewController presentViewController:productController animated:YES completion:nil];
            if ([self.delegate respondsToSelector:@selector(iRateDidPresentStoreKitModal)])
            {
                [self.delegate iRateDidPresentStoreKitModal];
            }
            return YES;
        }
    }
    
#endif

    if (self.verboseLogging)
    {
        NSLog(@"iRate will open the App Store ratings page using the following URL: %@", self.ratingsURL);
    }
    
    [[UIApplication sharedApplication] openURL:self.ratingsURL];
    return YES;
}

- (void)productViewControllerDidFinish:(UIViewController *)controller
{
    [controller.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    if ([self.delegate respondsToSelector:@selector(iRateDidDismissStoreKitModal)])
    {
        [self.delegate iRateDidDismissStoreKitModal];
    }
}

- (void)resizeAlertView:(UIAlertView *)alertView
{
    if ([[UIDevice currentDevice].systemVersion floatValue] < 7.0f)
    {
        NSInteger imageCount = 0;
        CGFloat offset = 0.0f;
        CGFloat messageOffset = 0.0f;
        for (UIView *view in alertView.subviews)
        {
            CGRect frame = view.frame;
            if ([view isKindOfClass:[UILabel class]])
            {
                UILabel *label = (UILabel *)view;
                if ([label.text isEqualToString:alertView.title])
                {
                    [label sizeToFit];
                    offset = label.frame.size.height - fmax(0.0f, 45.f - label.frame.size.height);
                    if (label.frame.size.height > frame.size.height)
                    {
                        offset = messageOffset = label.frame.size.height - frame.size.height;
                        frame.size.height = label.frame.size.height;
                    }
                }
                else if ([label.text isEqualToString:alertView.message])
                {
                    label.lineBreakMode = NSLineBreakByWordWrapping;
                    label.numberOfLines = 0;
                    label.alpha = 1.0f;
                    [label sizeToFit];
                    offset += label.frame.size.height - frame.size.height;
                    frame.origin.y += messageOffset;
                    frame.size.height = label.frame.size.height;
                }
            }
            else if ([view isKindOfClass:[UITextView class]])
            {
                view.alpha = 0.0f;
            }
            else if ([view isKindOfClass:[UIImageView class]])
            {
                if (imageCount++ > 0)
                {
                    view.alpha = 0.0f;
                }
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
}

- (void)willRotate
{
    [self performSelectorOnMainThread:@selector(didRotate) withObject:nil waitUntilDone:NO];
}

- (void)didRotate
{
    if (self.previousOrientation != [UIApplication sharedApplication].statusBarOrientation)
    {
        self.previousOrientation = [UIApplication sharedApplication].statusBarOrientation;
        [self resizeAlertView:self.visibleAlert];
    }
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
    [self resizeAlertView:alertView];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
    {        
        //ignore this version
        self.declinedThisVersion = YES;
        
        //log event
        if ([self.delegate respondsToSelector:@selector(iRateUserDidDeclineToRateApp)])
        {
            [self.delegate iRateUserDidDeclineToRateApp];
        }
    }
    else if (([self.cancelButtonLabel length] && buttonIndex == 2) ||
             ([self.cancelButtonLabel length] == 0 && buttonIndex == 1))
    {        
        //remind later
        self.lastReminded = [NSDate date];
        
        //log event
        if ([self.delegate respondsToSelector:@selector(iRateUserDidRequestReminderToRateApp)])
        {
            [self.delegate iRateUserDidRequestReminderToRateApp];
        }
    }
    else
    {
        //mark as rated
        self.ratedThisVersion = YES;
        
        //log event
        if ([self.delegate respondsToSelector:@selector(iRateUserDidAttemptToRateApp)])
        {
            [self.delegate iRateUserDidAttemptToRateApp];
        }
        
        if (![self.delegate respondsToSelector:@selector(iRateShouldOpenAppStore)] || [_delegate iRateShouldOpenAppStore])
        {
            //go to ratings page
            [self openRatingsPageInAppStore];
        }
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
        NSString *bundleID = [(__bridge NSDictionary *)cfDict objectForKey:(__bridge NSString *)kCFBundleIdentifierKey];
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

- (BOOL)openRatingsPageInAppStore
{
    if (!_ratingsURL && !self.appStoreID)
    {
        if (self.verboseLogging)
        {
            NSLog(@"iRate was unable to open the App Store because the app store ID is not set.");
        }
        return NO;
    }
    
    if (self.verboseLogging)
    {
        NSLog(@"iRate will open the App Store ratings page using the following URL: %@", self.ratingsURL);
    }
    
    [[NSWorkspace sharedWorkspace] openURL:self.ratingsURL];
    [self openAppPageWhenAppStoreLaunched];
    return YES;
}

- (void)alertDidEnd:(__unused NSAlert *)alert returnCode:(__unused NSInteger)returnCode contextInfo:(__unused void *)contextInfo
{
    switch (returnCode)
    {
        case NSAlertAlternateReturn:
        {
            //ignore this version
            self.declinedThisVersion = YES;
            
            //log event
            if ([self.delegate respondsToSelector:@selector(iRateUserDidDeclineToRateApp)])
            {
                [self.delegate iRateUserDidDeclineToRateApp];
            }

            break;
        }
        case NSAlertDefaultReturn:
        {
            //mark as rated
            self.ratedThisVersion = YES;
            
            //log event
            if ([self.delegate respondsToSelector:@selector(iRateUserDidAttemptToRateApp)])
            {
                [self.delegate iRateUserDidAttemptToRateApp];
            }
            
            if (![self.delegate respondsToSelector:@selector(iRateShouldOpenAppStore)] || [_delegate iRateShouldOpenAppStore])
            {
                //launch mac app store
                [self openRatingsPageInAppStore];
            }
            break;
        }
        default:
        {
            //remind later
            self.lastReminded = [NSDate date];
            
            //log event
            if ([self.delegate respondsToSelector:@selector(iRateUserDidRequestReminderToRateApp)])
            {
                [self.delegate iRateUserDidRequestReminderToRateApp];
            }
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
