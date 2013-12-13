//
//  iRate.h
//
//  Version 1.8.3
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


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"


#import <Availability.h>
#undef weak_delegate
#if __has_feature(objc_arc_weak) && \
(TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_8)
#define weak_delegate weak
#else
#define weak_delegate unsafe_unretained
#endif


#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif


extern NSUInteger const iRateAppStoreGameGenreID;
extern NSString *const iRateErrorDomain;


//localisation string keys
static NSString *const iRateMessageTitleKey = @"iRateMessageTitle";
static NSString *const iRateAppMessageKey = @"iRateAppMessage";
static NSString *const iRateGameMessageKey = @"iRateGameMessage";
static NSString *const iRateCancelButtonKey = @"iRateCancelButton";
static NSString *const iRateRemindButtonKey = @"iRateRemindButton";
static NSString *const iRateRateButtonKey = @"iRateRateButton";


typedef enum
{
    iRateErrorBundleIdDoesNotMatchAppStore = 1,
    iRateErrorApplicationNotFoundOnAppStore,
    iRateErrorApplicationIsNotLatestVersion,
    iRateErrorCouldNotOpenRatingPageURL
}
iRateErrorCode;


@protocol iRateDelegate <NSObject>
@optional

/**
 This method is called if iRate cannot connect to the App Store, usually because the network connection is down. This may also fire if your app does not have access to the network due to Sandbox permissions, in which case you will need to manually set the appStoreID so that iRate can still function.
 */
- (void)iRateCouldNotConnectToAppStore:(NSError *)error;

/**
 This method is called if iRate detects that the application has been updated since the last time it was launched.
 */
- (void)iRateDidDetectAppUpdate;

/**
 This method is called immediately before the rating prompt is displayed to the user. You can use this method to implement custom prompt logic. You can also use this method to block the standard prompt alert and display the rating prompt in a different way, or bypass it altogether.
 */
- (BOOL)iRateShouldPromptForRating;

/**
 This method is called immediately before the rating prompt is displayed. This is useful if you use analytics to track what percentage of users see the prompt and then go to the app store. This can help you fine tune the circumstances around when/how you show the prompt.
 */
- (void)iRateDidPromptForRating;

/**
 This is called when the user pressed the rate button in the rating prompt. This is useful if you want to log user interaction with iRate. This method is only called if you are using the standard iRate alert view prompt and will not be called automatically if you provide a custom rating implementation or call the openRatingsPageInAppStore method directly.
 */
- (void)iRateUserDidAttemptToRateApp;

/**
 This is called when the user declines to rate the app. This is useful if you want to log user interaction with iRate. This method is only called if you are using the standard iRate alert view prompt and will not be called automatically if you provide a custom rating implementation.
 */
- (void)iRateUserDidDeclineToRateApp;

/**
 This is called when the user asks to be reminded to rate the app. This is useful if you want to log user interaction with iRate. This method is only called if you are using the standard iRate alert view prompt and will not be called automatically if you provide a custom rating implementation.
 */
- (void)iRateUserDidRequestReminderToRateApp;

/**
 This method is called immediately before iRate attempts to open the app store. Return NO if you wish to implement your own ratings page display logic.
 */
- (BOOL)iRateShouldOpenAppStore;

/**
 This method is called immediately after iRate opens the app store.
 */
- (void)iRateDidOpenAppStore;

@end


@interface iRate : NSObject

+ (iRate *)sharedInstance;

/**
 This is only needed if your bundle ID is not unique between iOS and Mac app stores. This should match the iTunes app ID of your application, which you can get from iTunes connect after setting up your app. This value is not normally necessary and is generally only required if you have the aforementioned conflict between bundle IDs for your Mac and iOS apps, or in the case of Sandboxed Mac apps, if your app does not have network permission because it won't be able to fetch the appStoreID automatically using iTunes services.
 */
@property (nonatomic, assign) NSUInteger appStoreID;

/**
 This is set automatically. This is the type of app, used to determine the default text for the rating dialog. This is set automatically by calling an iTunes service, so you shouldn't need to set it manually for most purposes. If you do wish to override this value, setting it to the iRateAppStoreGameGenreID constant will cause iRate to use the "game" version of the rating dialog, and setting it to any other value will use the "app" version of the rating dialog.
 */
@property (nonatomic, assign) NSUInteger appStoreGenreID;

/**
 This is set automatically. This is the two-letter country code used to specify which iTunes store to check. It is set automatically from the device locale preferences, so shouldn't need to be changed in most cases. You can override this to point to the US store, or another specific store if you prefer, which may be a good idea if your app is only available in certain countries.
 */
@property (nonatomic, copy) NSString *appStoreCountry;

/**
 This is set automatically. This is the name of the app displayed in the iRate alert. It is set automatically from the application's info.plist, but you may wish to override it with a shorter or longer version.
 */
@property (nonatomic, copy) NSString *applicationName;

/**
 This is set automatically.
 */
@property (nonatomic, copy) NSString *applicationVersion;

/**
 This is set automatically. This is the application bundle ID, used to retrieve the appStoreID and appStoreGenreID from iTunes. This is set automatically from the app's info.plist, so you shouldn't need to change it except for testing purposes.
 */
@property (nonatomic, copy) NSString *applicationBundleID;


/**
 This has sensible defaults. This is the minimum number of times the user must launch the app before they are prompted to rate it. This avoids the scenario where a user runs the app once, doesn't look at it for weeks and then launches it again, only to be immediately prompted to rate it. The minimum use count ensures that only frequent users are prompted. The prompt will appear only after the specified number of days AND uses has been reached. This defaults to 10 uses.
 */
@property (nonatomic, assign) NSUInteger usesUntilPrompt;

/**
 This has sensible defaults. For some apps, launches are not a good metric for usage. For example the app might be a daemon that runs constantly, or a game where the user can't write an informed review until they've reached a particular level. In this case you can manually log significant events and have the prompt appear after a predetermined number of these events. Like the usesUntilPrompt setting, the prompt will appear only after the specified number of days AND events, however once the day threshold is reached, the prompt will appear if EITHER the event threshold OR uses threshold is reached. This defaults to 10 events.
 */
@property (nonatomic, assign) NSUInteger eventsUntilPrompt;

/**
 This has sensible defaults. This is the number of days the user must have had the app installed before they are prompted to rate it. The time is measured from the first time the app is launched. This is a floating point value, so it can be used to specify a fractional number of days (e.g. 0.5). The default value is 10 days.
 */
@property (nonatomic, assign) float daysUntilPrompt;

/**
 This has sensible defaults. If you are less concerned with the total number of times the app is used, but would prefer to use the frequency of times the app is used, you can use the usesPerWeekForPrompt property to set a minimum threshold for the number of times the user must launch the app per week (on average) for the prompt to be shown. Note that this is the average since the app was installed, so if the user goes for a long period without running the app, it may throw off the average. The default value is zero.
 */
@property (nonatomic, assign) float usesPerWeekForPrompt;

/**
 This has sensible defaults. How long the app should wait before reminding a user to rate after they select the "remind me later" option (measured in days). A value of zero means the app will remind the user next launch. Note that this value supersedes the other criteria, so the app won't prompt for a rating during the reminder period, even if a new version is released in the meantime. This defaults to 1 day.
 */
@property (nonatomic, assign) float remindPeriod;

/**
 The title displayed for the rating prompt. If you don't want to display a title then set this to @"";
 */
@property (nonatomic, copy) NSString *messageTitle;

/**
 The rating prompt message. This should be polite and courteous, but not too wordy. If you don't want to display a message then set this to @"";
 */
@property (nonatomic, copy) NSString *message;

/**
 The button label for the button to dismiss the rating prompt without rating the app.
 */
@property (nonatomic, copy) NSString *cancelButtonLabel;

/**
 The button label for the button the user presses if they don't want to rate the app immediately, but do want to be reminded about it in future. Set this to @"" if you don't want to display the remind me button - e.g. if you don't have space on screen.
 */
@property (nonatomic, copy) NSString *remindButtonLabel;

/**
 The button label for the button the user presses if they do want to rate the app.
 */
@property (nonatomic, copy) NSString *rateButtonLabel;

/**
 By default, iRate will use all available languages in the iRate.bundle, even if used in an app that does not support localisation. If you would prefer to restrict iRate to only use the same set of languages that your application already supports, set this property to NO. (Defaults to YES).
 */
@property (nonatomic, assign) BOOL useAllAvailableLanguages;

/**
 Because iTunes ratings are version-specific, you ideally want users to rate each new version of your app. However, it's debatable whether many users will actually do this, and if you update frequently this may get annoying. Set promptAgainForEachNewVersion to NO, and iRate won't prompt the user again each time they install an update if they've already rated the app. It will still prompt them each new version if they have not rated the app, but you can override this using the iRateShouldShouldPromptForRating delegate method if you wish.
 */
@property (nonatomic, assign) BOOL promptAgainForEachNewVersion;

/**
 Set this to NO to enabled the rating prompt to be displayed even if the user is not running the latest version of the app. This defaults to YES because that way users won't leave bad reviews due to bugs that you've already fixed, etc.
 */
@property (nonatomic, assign) BOOL onlyPromptIfLatestVersion;

/**
 This setting is applicable to Mac OS only. By default, on Mac OS the iRate alert is displayed as sheet on the main window. Some applications do not have a main window, so this approach doesn't work. For such applications, set this property to NO to allow the iRate alert to be displayed as a regular modal window.
 */
@property (nonatomic, assign) BOOL onlyPromptIfMainWindowIsAvailable;

/**
 Set this to NO to disable the rating prompt appearing automatically when the application launches or returns from the background. The rating criteria will continue to be tracked, but the prompt will not be displayed automatically while this setting is in effect. You can use this option if you wish to manually control display of the rating prompt.
 */
@property (nonatomic, assign) BOOL promptAtLaunch;

/**
 This option will cause iRate to send detailed logs to the console about the prompt decision process. If your app is not correctly prompting for a rating when you would expect it to, this will help you figure out why. Verbose logging is enabled by default on debug builds, and disabled on release and deployment builds.
 */
@property (nonatomic, assign) BOOL verboseLogging;

/**
 If set to YES, iRate will always display the rating prompt on launch, regardless of how long the app has been in use or whether it's the latest version. Use this to proofread your message and check your configuration is correct during testing, but disable it for the final release (defaults to NO).
 */
@property (nonatomic, assign) BOOL previewMode;

/**
 The URL that the app will direct the user to so they can write a rating for the app. This is set to the correct value for the given platform automatically. On iOS 6 and below this takes users directly to the ratings page, but on iOS 7 and Mac OS it takes users to the main app page (if there is a way to directly link to the ratings page on those platforms, I've yet to find it). If you are implementing your own rating prompt, you should probably use the openRatingsPageInAppStore method instead, especially on Mac OS, as the process for opening the Mac app store is more complex than merely opening the URL.
 */
@property (nonatomic, strong) NSURL *ratingsURL;

/**
 The first date on which the user launched the current version of the app. This is used to calculate whether the daysUntilPrompt criterion has been met.
 */
@property (nonatomic, strong) NSDate *firstUsed;

/**
 The date on which the user last requested to be reminded to rate the app later.
 */
@property (nonatomic, strong) NSDate *lastReminded;

/**
 The number of times the current version of the app has been used (launched).
 */
@property (nonatomic, assign) NSUInteger usesCount;

/**
 The number of significant application events that have been recorded since the current version was installed. This is incremented by the logEvent method, but can also be manipulated directly. Check out the Events Demo to see how this os used.
 */
@property (nonatomic, assign) NSUInteger eventCount;

/**
 The average number of times per week that the current version of the app has been used (launched).
 */
@property (nonatomic, readonly) float usesPerWeek;

/**
 This flag indicates whether the user has declined to rate the current version (YES) or not (NO).
 */
@property (nonatomic, assign) BOOL declinedThisVersion;

/**
 This flag indicates whether the user has declined to rate any previous version of the app (YES) or not (NO). This is not currently used by the iRate prompting logic, but may be useful for implementing your own rules using the iRateShouldPromptForRating delegate method.
 */
@property (nonatomic, readonly) BOOL declinedAnyVersion;

/**
 This flag indicates whether the user has already rated the current version (YES) or not (NO).
 */
@property (nonatomic, assign) BOOL ratedThisVersion;

/**
 This (readonly) flag indicates whether the user has previously rated any version of the app (YES) or not (NO).
 */
@property (nonatomic, readonly) BOOL ratedAnyVersion;

/**
 An object you have supplied that implements the iRateDelegate protocol, documented below. Use this to detect and/or override iRate's default behaviour. This defaults to the App Delegate, so if you are using your App Delegate as your iRate delegate, you don't need to set this property.
 */
@property (nonatomic, weak_delegate) id<iRateDelegate> delegate;

/**
 Returns YES if the prompt criteria have been met, and NO if they have not. You can use this to decide when to display a rating prompt if you have disabled the automatic display at app launch.
 */
- (BOOL)shouldPromptForRating;

/**
 This method will immediately trigger the rating prompt without checking that the app store is available, and without calling the iRateShouldShouldPromptForRating delegate method. Note that this method depends on the appStoreID and applicationGenre properties, which are only retrieved after polling the iTunes server, so if you intend to call this method directly, you will need to set these properties yourself beforehand, or use the promptIfNetworkAvailable method instead.
 */
- (void)promptForRating;

/**
 This method will check if the app store is available, and if it is, it will display the rating prompt to the user. The iRateShouldShouldPromptForRating delegate method will be called before the alert is shown, so you can intercept it. Note that if your app is sandboxed and does not have the network access permission, this method will ignore the network availability status, however in this case you will need to manually set the appStoreID or iRate cannot function.
 */
- (void)promptIfNetworkAvailable;

/**
 This method skips the user alert and opens the application ratings page in the Mac or iPhone app store, depending on which platform iRate is running on. This method does not perform any checks to verify that the machine has network access or that the app store is available. It also does not call the -iRateShouldOpenAppStore delegate method. You should use this method to open the ratings page instead of the ratingsURL property, as the process for launching the app store is more complex than merely opening the URL in many cases. Note that this method depends on the appStoreID which is only retrieved after polling the iTunes server. If you call this method without first doing an update check, you will either need to set the appStoreID property yourself beforehand, or risk that the method may take some time to make a network call, or fail entirely. On success, this method will call the -iRateDidOpenAppStore delegate method. On Failure it will call the -iRateCouldNotConnectToAppStore: delegate method.
 */
- (void)openRatingsPageInAppStore;

/**
 This method can be called from anywhere in your app (after iRate has been configured) and increments the iRate significant event count. When the predefined number of events is reached, the rating prompt will be shown. The optional deferPrompt parameter is used to determine if the prompt will be shown immediately (NO) or if the app will wait until the next launch (YES).
 */
- (void)logEvent:(BOOL)deferPrompt;

@end


#pragma GCC diagnostic pop
