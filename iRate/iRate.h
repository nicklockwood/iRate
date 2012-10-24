//
//  iRate.h
//
//  Version 1.6.2
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

//
//  ARC Helper
//
//  Version 2.1
//
//  Created by Nick Lockwood on 05/01/2012.
//  Copyright 2012 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://gist.github.com/1563325
//

#ifndef ah_retain
#if __has_feature(objc_arc)
#define ah_retain self
#define ah_dealloc self
#define release self
#define autorelease self
#else
#define ah_retain retain
#define ah_dealloc dealloc
#define __bridge
#endif
#endif

//  Weak delegate support

#ifndef ah_weak
#import <Availability.h>
#if (__has_feature(objc_arc)) && \
((defined __IPHONE_OS_VERSION_MIN_REQUIRED && \
__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_5_0) || \
(defined __MAC_OS_X_VERSION_MIN_REQUIRED && \
__MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_7))
#define ah_weak weak
#define __ah_weak __weak
#else
#define ah_weak unsafe_unretained
#define __ah_weak __unsafe_unretained
#endif
#endif

//  ARC Helper ends


#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
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
    iRateErrorApplicationIsNotLatestVersion
}
iRateErrorCode;


@protocol iRateDelegate <NSObject>
@optional

- (void)iRateCouldNotConnectToAppStore:(NSError *)error;
- (void)iRateDidDetectAppUpdate;
- (BOOL)iRateShouldPromptForRating;
- (void)iRateUserDidAttemptToRateApp;
- (void)iRateUserDidDeclineToRateApp;
- (void)iRateUserDidRequestReminderToRateApp;

@end


@interface iRate : NSObject

//required for 32-bit Macs
#ifdef __i386
{
    @private
    
    NSUInteger _appStoreID;
    NSUInteger _appStoreGenreID;
    NSString *_appStoreCountry;
    NSString *_applicationName;
    NSString *_applicationVersion;
    NSString *_applicationBundleID;
    NSUInteger _usesUntilPrompt;
    NSUInteger _eventsUntilPrompt;
    float _daysUntilPrompt;
    float _usesPerWeekForPrompt;
    float _remindPeriod;
    NSString *_messageTitle;
    NSString *_message;
    NSString *_cancelButtonLabel;
    NSString *_remindButtonLabel;
    NSString *_rateButtonLabel;
    NSURL *_ratingsURL;
    BOOL _useAllAvailableLanguages;
    BOOL _disableAlertViewResizing;
    BOOL _promptAgainForEachNewVersion;
    BOOL _onlyPromptIfLatestVersion;
    BOOL _onlyPromptIfMainWindowIsAvailable;
    BOOL _promptAtLaunch;
    BOOL _verboseLogging;
    BOOL _previewMode;
    id<iRateDelegate> __ah_weak _delegate;
    id _visibleAlert;
    int _previousOrientation;
    BOOL _currentlyChecking;
}
#endif

+ (iRate *)sharedInstance;

//app store ID - this is only needed if your
//bundle ID is not unique between iOS and Mac app stores
@property (nonatomic, assign) NSUInteger appStoreID;

//application details - these are set automatically
@property (nonatomic, assign) NSUInteger appStoreGenreID;
@property (nonatomic, copy) NSString *appStoreCountry;
@property (nonatomic, copy) NSString *applicationName;
@property (nonatomic, copy) NSString *applicationVersion;
@property (nonatomic, copy) NSString *applicationBundleID;

//usage settings - these have sensible defaults
@property (nonatomic, assign) NSUInteger usesUntilPrompt;
@property (nonatomic, assign) NSUInteger eventsUntilPrompt;
@property (nonatomic, assign) float daysUntilPrompt;
@property (nonatomic, assign) float usesPerWeekForPrompt;
@property (nonatomic, assign) float remindPeriod;

//message text, you may wish to customise these
@property (nonatomic, copy) NSString *messageTitle;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *cancelButtonLabel;
@property (nonatomic, copy) NSString *remindButtonLabel;
@property (nonatomic, copy) NSString *rateButtonLabel;

//debugging and prompt overrides
@property (nonatomic, assign) BOOL useAllAvailableLanguages;
@property (nonatomic, assign) BOOL disableAlertViewResizing;
@property (nonatomic, assign) BOOL promptAgainForEachNewVersion;
@property (nonatomic, assign) BOOL onlyPromptIfLatestVersion;
@property (nonatomic, assign) BOOL onlyPromptIfMainWindowIsAvailable;
@property (nonatomic, assign) BOOL promptAtLaunch;
@property (nonatomic, assign) BOOL verboseLogging;
@property (nonatomic, assign) BOOL previewMode;

//advanced properties for implementing custom behaviour
@property (nonatomic, strong) NSURL *ratingsURL;
@property (nonatomic, strong) NSDate *firstUsed;
@property (nonatomic, strong) NSDate *lastReminded;
@property (nonatomic, assign) NSUInteger usesCount;
@property (nonatomic, assign) NSUInteger eventCount;
@property (nonatomic, readonly) float usesPerWeek;
@property (nonatomic, assign) BOOL declinedThisVersion;
@property (nonatomic, readonly) BOOL declinedAnyVersion;
@property (nonatomic, assign) BOOL ratedThisVersion;
@property (nonatomic, readonly) BOOL ratedAnyVersion;
@property (nonatomic, ah_weak) id<iRateDelegate> delegate;

//manually control behaviour
- (BOOL)shouldPromptForRating;
- (void)promptForRating;
- (void)promptIfNetworkAvailable;
- (void)openRatingsPageInAppStore;
- (void)logEvent:(BOOL)deferPrompt;

@end
