Purpose
--------------

iRate is a library to help you promote your iPhone and Mac App Store apps by prompting users to rate the app after using it for a few days. This approach is one of the best ways to get positive app reviews by targeting only regular users (who presumably like the app or they wouldn't keep using it!).


Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 7.1 / Mac OS 10.9 (Xcode 5.1, Apple LLVM compiler 5.1)
* Earliest supported deployment target - iOS 5.0 / Mac OS 10.7
* Earliest compatible deployment target - iOS 4.3 / Mac OS 10.6

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this OS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

As of version 1.7, iRate requires ARC. If you wish to use iRate in a non-ARC project, just add the -fobjc-arc compiler flag to the iRate.m class. To do this, go to the Build Phases tab in your target settings, open the Compile Sources group, double-click iRate.m in the list and type -fobjc-arc into the popover.

If you wish to convert your whole project to ARC, comment out the #error line in iRate.m, then run the Edit > Refactor > Convert to Objective-C ARC... tool in Xcode and make sure all files that you wish to use ARC for (including iRate.m) are checked.


Thread Safety
--------------

iRate uses threading internally to avoid blocking the UI, but none of the iRate external interfaces are thread safe and you should not call any methods or set any properties on iRate except from the main thread.


Installation
--------------

To install iRate into your app, drag the iRate.h, .m and .bundle files into your project. You can omit the .bundle if you are not interested in localised text.

iRate typically requires no configuration at all and will simply run automatically, using the application's bundle ID to look the app ID up on the App Store.

**Note:** If you have apps with matching bundle IDs on both the Mac and iOS app stores (even if they use different capitalisation), the lookup mechanism won't work, so you'll need to manually set the appStoreID property, which is a numeric ID that can be found in iTunes Connect after you set up an app. Also, if you are creating a sandboxed Mac app and your app does not request the network access permission then you will need to set the appStoreID because it cannot be retrieved from the iTunes service. 

If you do wish to customise iRate, the best time to do this is *before* the app has finished launching. The easiest way to do this is to add the iRate configuration code in your AppDelegate's `initialize` method, like this:

    #import "iRate.h"

	+ (void)initialize
	{
		//configure iRate
		[iRate sharedInstance].daysUntilPrompt = 5;
		[iRate sharedInstance].usesUntilPrompt = 15;
	}


Configuration
--------------

To configure iRate, there are a number of properties of the iRate class that can alter the behaviour and appearance of iRate. These should be mostly self- explanatory, but they are documented below:

    @property (nonatomic, assign) NSUInteger appStoreID;

This should match the iTunes app ID of your application, which you can get from iTunes connect after setting up your app. This value is not normally necessary and is generally only required if you have the aforementioned conflict between bundle IDs for your Mac and iOS apps, or in the case of Sandboxed Mac apps, if your app does not have network permission because it won't be able to fetch the appStoreID automatically using iTunes services.

    @property (nonatomic, assign) NSUInteger appStoreGenreID;

This is the type of app, used to determine the default text for the rating dialog. This is set automatically by calling an iTunes service, so you shouldn't need to set it manually for most purposes. If you do wish to override this value, setting it to the `iRateAppStoreGameGenreID` constant will cause iRate to use the "game" version of the rating dialog, and setting it to any other value will use the "app" version of the rating dialog.

    @property (nonatomic, copy) NSString *appStoreCountry;

This is the two-letter country code used to specify which iTunes store to check. It is set automatically from the device locale preferences, so shouldn't need to be changed in most cases. You can override this to point to the US store, or another specific store if you prefer, which may be a good idea if your app is only available in certain countries.

    @property (nonatomic, copy) NSString *applicationName;

This is the name of the app displayed in the iRate alert. It is set automatically from the application's info.plist, but you may wish to override it with a shorter or longer version.

    @property (nonatomic, copy) NSString *applicationBundleID;

This is the application bundle ID, used to retrieve the `appStoreID` and `appStoreGenreID` from iTunes. This is set automatically from the app's info.plist, so you shouldn't need to change it except for testing purposes.

    @property (nonatomic, assign) float daysUntilPrompt;

This is the number of days the user must have had the app installed before they are prompted to rate it. The time is measured from the first time the app is launched. This is a floating point value, so it can be used to specify a fractional number of days (e.g. 0.5). The default value is 10 days.

    @property (nonatomic, assign) NSUInteger usesUntilPrompt;

This is the minimum number of times the user must launch the app before they are prompted to rate it. This avoids the scenario where a user runs the app once, doesn't look at it for weeks and then launches it again, only to be immediately prompted to rate it. The minimum use count ensures that only frequent users are prompted. The prompt will appear only after the specified number of days AND uses has been reached. This defaults to 10 uses.

    @property (nonatomic, assign) NSUInteger eventsUntilPrompt;

For some apps, launches are not a good metric for usage. For example the app might be a daemon that runs constantly, or a game where the user can't write an informed review until they've reached a particular level. In this case you can manually log significant events and have the prompt appear after a predetermined number of these events. Like the usesUntilPrompt setting, the prompt will appear only after the specified number of days AND events, however once the day threshold is reached, the prompt will appear if EITHER the event threshold OR uses threshold is reached. This defaults to 10 events.

    @property (nonatomic, assign) float usesPerWeekForPrompt;

If you are less concerned with the total number of times the app is used, but would prefer to use the *frequency* of times the app is used, you can use the `usesPerWeekForPrompt` property to set a minimum threshold for the number of times the user must launch the app per week (on average) for the prompt to be shown. Note that this is the average since the app was installed, so if the user goes for a long period without running the app, it may throw off the average. The default value is zero.

    @property (nonatomic, assign) float remindPeriod;

How long the app should wait before reminding a user to rate after they select the "remind me later" option (measured in days). A value of zero means the app will remind the user next launch. Note that this value supersedes the other criteria, so the app won't prompt for a rating during the reminder period, even if a new version is released in the meantime.  This defaults to 1 day.

    @property (nonatomic, copy) NSString *messageTitle;

The title displayed for the rating prompt. If you don't want to display a title then set this to `@""`;

    @property (nonatomic, copy) NSString *message;

The rating prompt message. This should be polite and courteous, but not too wordy. If you don't want to display a message then set this to `@""`;

    @property (nonatomic, copy) NSString *updateMessage;
    
This is a message to be used for users who have previously rated the app, encouraging them to re-rate. This allows you to customise the message for these users. If you do not supply a custom message for this case, the standard message will be used.

    @property (nonatomic, copy) NSString *cancelButtonLabel;

The button label for the button to dismiss the rating prompt without rating the app.

    @property (nonatomic, copy) NSString *rateButtonLabel;

The button label for the button the user presses if they do want to rate the app.

    @property (nonatomic, copy) NSString *remindButtonLabel;

The button label for the button the user presses if they don't want to rate the app immediately, but do want to be reminded about it in future. Set this to `@""` if you don't want to display the remind me button - e.g. if you don't have space on screen.

    @property (nonatomic, assign) BOOL useAllAvailableLanguages;

By default, iRate will use all available languages in the iRate.bundle, even if used in an app that does not support localisation. If you would prefer to restrict iRate to only use the same set of languages that your application already supports, set this property to NO. (Defaults to YES).

    @property (nonatomic, assign) BOOL promptForNewVersionIfUserRated;
    
Because iTunes ratings are version-specific, you ideally want users to rate each new version of your app. Users who really love your app may be willing to update their review for new releases. Set `promptForNewVersionIfUserRated` to `YES`, and iRate will prompt the user again each time they install an update until they decline to rate the app. If they decline, they will not be asked again.

    @property (nonatomic, assign) BOOL onlyPromptIfLatestVersion;

Set this to NO to enabled the rating prompt to be displayed even if the user is not running the latest version of the app. This defaults to YES because that way users won't leave bad reviews due to bugs that you've already fixed, etc.

    @property (nonatomic, assign) BOOL onlyPromptIfMainWindowIsAvailable;

This setting is applicable to Mac OS only. By default, on Mac OS the iRate alert is displayed as sheet on the main window. Some applications do not have a main window, so this approach doesn't work. For such applications, set this property to NO to allow the iRate alert to be displayed as a regular modal window.

    @property (nonatomic, assign) BOOL promptAtLaunch;

Set this to NO to disable the rating prompt appearing automatically when the application launches or returns from the background. The rating criteria will continue to be tracked, but the prompt will not be displayed automatically while this setting is in effect. You can use this option if you wish to manually control display of the rating prompt.

    @property (nonatomic, assign) BOOL verboseLogging;

This option will cause iRate to send detailed logs to the console about the prompt decision process. If your app is not correctly prompting for a rating when you would expect it to, this will help you figure out why. Verbose logging is enabled by default on debug builds, and disabled on release and deployment builds.

    @property (nonatomic, assign) BOOL previewMode;

If set to YES, iRate will always display the rating prompt on launch, regardless of how long the app has been in use or whether it's the latest version (unless you have explicitly disabled the `promptAtLaunch` option). Use this to proofread your message and check your configuration is correct during testing, but disable it for the final release (defaults to NO).


Advanced properties
--------------

If the default iRate behaviour doesn't meet your requirements, you can implement your own by using the advanced properties, methods and delegate. The properties below let you access internal state and override it:

    @property (nonatomic, strong) NSURL *ratingsURL;

The URL that the app will direct the user to so they can write a rating for the app. This is set to the correct value for the given platform automatically. On iOS 6 and below this takes users directly to the ratings page, but on iOS 7 and Mac OS it takes users to the main app page (if there is a way to directly link to the ratings page on those platforms, I've yet to find it). If you are implementing your own rating prompt, you should probably use the `openRatingsPageInAppStore` method instead, especially on Mac OS, as the process for opening the Mac app store is more complex than merely opening the URL.

    @property (nonatomic, strong) NSDate *firstUsed;

The first date on which the user launched the current version of the app. This is used to calculate whether the daysUntilPrompt criterion has been met.

    @property (nonatomic, strong) NSDate *lastReminded;

The date on which the user last requested to be reminded to rate the app later.

    @property (nonatomic, assign) NSUInteger usesCount;

The number of times the current version of the app has been used (launched).

    @property (nonatomic, assign) NSUInteger eventCount;

The number of significant application events that have been recorded since the current version was installed. This is incremented by the logEvent method, but can also be manipulated directly. Check out the *Events Demo* to see how this os used. 

    @property (nonatomic, readonly) float usesPerWeek;

The average number of times per week that the current version of the app has been used (launched).

    @property (nonatomic, assign) BOOL declinedThisVersion;

This flag indicates whether the user has declined to rate the current version (YES) or not (NO). This is not currently used by the iRate prompting logic, but may be useful for implementing your own logic.

    @property (nonatomic, assign) BOOL declinedAnyVersion;

This flag indicates whether the user has declined to rate any previous version of the app (YES) or not (NO). iRate will not prompt the user automatically if this is set to YES.

    @property (nonatomic, assign) BOOL ratedThisVersion;

This flag indicates whether the user has already rated the current version (YES) or not (NO).

    @property (nonatomic, readonly) BOOL ratedAnyVersion;

This (readonly) flag indicates whether the user has previously rated any version of the app (YES) or not (NO).

    @property (nonatomic, assign) id<iRateDelegate> delegate;

An object you have supplied that implements the `iRateDelegate` protocol, documented below. Use this to detect and/or override iRate's default behaviour. This defaults to the App Delegate, so if you are using your App Delegate as your iRate delegate, you don't need to set this property. 


Methods
--------------

Besides configuration, iRate has the following methods:

    - (void)logEvent:(BOOL)deferPrompt;

This method can be called from anywhere in your app (after iRate has been configured) and increments the iRate significant event count. When the predefined number of events is reached, the rating prompt will be shown. The optional deferPrompt parameter is used to determine if the prompt will be shown immediately (NO) or if the app will wait until the next launch (YES).

    - (BOOL)shouldPromptForRating;

Returns YES if the prompt criteria have been met, and NO if they have not. You can use this to decide when to display a rating prompt if you have disabled the automatic display at app launch.

    - (void)promptForRating;

This method will immediately trigger the rating prompt without checking that the  app store is available, and without calling the iRateShouldShouldPromptForRating delegate method. Note that this method depends on the `appStoreID` and `applicationGenre` properties, which are only retrieved after polling the iTunes server, so if you intend to call this method directly, you will need to set these properties yourself beforehand, or use the `promptIfNetworkAvailable` method instead.

    - (void)promptIfNetworkAvailable;

This method will check if the app store is available, and if it is, it will display the rating prompt to the user. The iRateShouldShouldPromptForRating delegate method will be called before the alert is shown, so you can intercept it. Note that if your app is sandboxed and does not have the network access permission, this method will ignore the network availability status, however in this case you will need to manually set the appStoreID or iRate cannot function.

    - (void)openRatingsPageInAppStore;

This method skips the user alert and opens the application ratings page in the Mac or iPhone app store, depending on which platform iRate is running on. This method does not perform any checks to verify that the machine has network access or that the app store is available. It also does not call the `-iRateShouldOpenAppStore` delegate method. You should use this method to open the ratings page instead of the ratingsURL property, as the process for launching the app store is more complex than merely opening the URL in many cases. Note that this method depends on the `appStoreID` which is only retrieved after polling the iTunes server. If you call this method without first doing an update check, you will either need to set the `appStoreID` property yourself beforehand, or risk that the method may take some time to make a network call, or fail entirely. On success, this method will call the `-iRateDidOpenAppStore` delegate method. On Failure it will call the `-iRateCouldNotConnectToAppStore:` delegate method.


Delegate methods
---------------

The iRateDelegate protocol provides the following methods that can be used intercept iRate events and override the default behaviour. All methods are optional.

    - (void)iRateCouldNotConnectToAppStore:(NSError *)error;

This method is called if iRate cannot connect to the App Store, usually because the network connection is down. This may also fire if your app does not have access to the network due to Sandbox permissions, in which case you will need to manually set the appStoreID so that iRate can still function.

    - (void)iRateDidDetectAppUpdate;

This method is called if iRate detects that the application has been updated since the last time it was launched.

    - (BOOL)iRateShouldShouldPromptForRating;

This method is called immediately before the rating prompt is displayed to the user. You can use this method to implement custom prompt logic in addition to the standard rules. You can also use this method to block the standard prompt alert and display the rating prompt in a different way, or bypass it altogether.

    - (void)iRateDidPromptForRating;

This method is called immediately before the rating prompt is displayed. This is useful if you use analytics to track what percentage of users see the prompt and then go to the app store. This can help you fine tune the circumstances around when/how you show the prompt.

    - (void)iRateUserDidAttemptToRateApp;
    
This is called when the user pressed the rate button in the rating prompt. This is useful if you want to log user interaction with iRate. This method is only called if you are using the standard iRate alert view prompt and will not be called automatically if you provide a custom rating implementation or call the `openRatingsPageInAppStore` method directly.
    
    - (void)iRateUserDidDeclineToRateApp;
    
This is called when the user declines to rate the app. This is useful if you want to log user interaction with iRate. This method is only called if you are using the standard iRate alert view prompt and will not be called automatically if you provide a custom rating implementation.
    
    - (void)iRateUserDidRequestReminderToRateApp;

This is called when the user asks to be reminded to rate the app. This is useful if you want to log user interaction with iRate. This method is only called if you are using the standard iRate alert view prompt and will not be called automatically if you provide a custom rating implementation.

    - (BOOL)iRateShouldOpenAppStore;
    
This method is called immediately before iRate attempts to open the app store. Return NO if you wish to implement your own ratings page display logic.

    - (void)iRateDidOpenAppStore;

This method is called immediately after iRate opens the app store.


Localisation
---------------

The default strings for iRate are already localised for many languages. By default, iRate will use all the localisations in the iRate.bundle even in an app that is not localised, or which is only localised to a subset of the languages that iRate supports. The iRate strings keys are:

    static NSString *const iRateMessageTitleKey = @"iRateMessageTitle";
    static NSString *const iRateAppMessageKey = @"iRateAppMessage";
    static NSString *const iRateGameMessageKey = @"iRateGameMessage";
    static NSString *const iRateUpdateMessageKey = @"iRateUpdateMessage";
    static NSString *const iRateCancelButtonKey = @"iRateCancelButton";
    static NSString *const iRateRemindButtonKey = @"iRateRemindButton";
    static NSString *const iRateRateButtonKey = @"iRateRateButton";

If you would prefer iRate to only use the localisations that are enabled in your application (so that if your app only supports English, French and Spanish, iRate will automatically be localised for those languages, but not for German, even though iRate includes a German language file), set the `useAllAvailableLanguages` option to NO.

It is not recommended that you modify the strings files in the iRate.bundle, as it will complicate updating to newer versions of iRate. The exception to this is if you would like to submit additional languages or improvements or corrections to the localisations in the iRate project on github (which are greatly appreciated).

If you want to add an additional language for iRate in your app without submitting them back to the github project, you can add these strings directly to the appropriate Localizable.strings file in your project folder. If you wish to replace some or all of the default iRate strings, the simplest option is to copy just those strings into your own Localizable.strings file and then modify them. iRate will automatically use strings in the main application bundle in preference to the ones in the iRate bundle so you can override any string in this way.

If you do not want to use *any* of the default localisations, you can omit the iRate.bundle altogether. Note that if you only want to support a subset of languages that iRate supports, it is not neccesary to delete the other strings files from iRate.bundle - just set `useAllAvailableLanguages` to NO, and iRate will only use the languages that your app already supports.

The old method of overriding iRate's default strings by using individual setter methods (see below) is still supported, however the recommended approach is now to add those strings to your project's Localizable.strings file, which will be detected automatically by iRate.

    + (void)initialize
    {
        //overriding the default iRate strings
        [iRate sharedInstance].messageTitle = NSLocalizedString(@"Rate MyApp", @"iRate message title");
        [iRate sharedInstance].message = NSLocalizedString(@"If you like MyApp, please take the time, etc", @"iRate message");
        [iRate sharedInstance].cancelButtonLabel = NSLocalizedString(@"No, Thanks", @"iRate decline button");
        [iRate sharedInstance].remindButtonLabel = NSLocalizedString(@"Remind Me Later", @"iRate remind button");
        [iRate sharedInstance].rateButtonLabel = NSLocalizedString(@"Rate It Now", @"iRate accept button");
    }


Example Projects
---------------

When you build and run the basic Mac or iPhone example project for the first time, it will show an alert asking you to rate the app. This is because the previewMode option is set.

Disable the previewMode option and play with the other settings to see how the app behaves in practice.


Advanced Example
---------------

The advanced example demonstrates how you might implement a completely bespoke iRate interface using the iRateDelegate methods. Automatic prompting is disabled and instead the user can opt to rate the app by pressing the "Rate this app" button.

When pressed, the app first checks that the app store is available (it may not be if the computer has no Internet connection or apple.com is down), and then launches the Mac App Store.

The example is for Mac OS, but the same principle can be applied on iOS.


Release Notes
-----------------

Version 1.10.2

- Added -isFirstUse method
- Fixed bug where app would never prompt for rating after an upgrade if it had not already done so
- Improved italian localization

Version 1.10.1

- Fixed serious bug that prevents rating prompt appearing for any new apps
- Fixed issue where bad response from iTunes would be cached indefinitely

Version 1.10

- Now links directly to review page again on iOS 7.1 + (Apple has fixed support)
- No longer interrupts rating popups for the full daysUntilPrompt period after an app update
- Added promptForNewVersionIfUserRated option to re-prompt users who have previous rated (off by default)
- Added updateMessage property for use with promptForNewVersionIfUserRated option
- Fixed typo in French translation

Version 1.9.3

- No longer logs warning if app ID is not found, unless in verbose mode
- Minor translation fix for Vietnamese

Version 1.9.2

- Added Bengali, Farsi, Hindi, Punjabi, Thai and Vietnamese translations

Version 1.9.1

- Fixed problem with fetching app ID when device region is set to Europe

Version 1.9

- iRate will no longer ask users to rate the app again each version
- If the user selects "No, Thanks", they will now never be asked again
- Removed the `promptAgainEachVersion` option

Version 1.8.3

- Stricter warning compliance
- Now uses macros to avoid generating warnings when imported into apps with even stricter warning settings

Version 1.8.2

- Fixed issue where checkForConnectivityInBackground could be called on main thread, blocking user interaction

Version 1.8.1

- Added iRateDidOpenAppStore delegate method
- Language selection now works correctly if the user has an unsupported language
- Removed all support for StoreKit, as Apple have disabled the StoreKit rating panel
- Calling openRatingsPageInAppStore will now look up appStoreID automatically if not already known
- Improved error messaging when using iRate on the iOS Simulator
- Added Greek and Slovenian localizations

Version 1.8

- App store link works on iOS 7 (had to link to app home page instead of directly to reviews page for now - hopefully an alternative direct link can be found)
- Now uses NSJSONSerializer if available (iOS 4.x will still use the old parser)
- No longer requires StoreKit by default (see README for details)
- Fixed Czech and Austrian German locales for iOS 7
- Removed disableAlertViewResizing property (no longer needed)
- Improved Czech translation
- Improved French translation
- Urdu support
- Fixed bug in alertview resizing for iOS 6 and below
- Now complies with the -Wextra warning level

Version 1.7.5

- Improved Arabic translation
- Improved podspec file
- Removed .DS_Store file

Version 1.7.4

- Added Arabic translation
- Improved French translation
- Added delegate method for tracking when prompt gets shown

Version 1.7.3

- Added Slovak, Czech and Austrian translations
- Fixed some bugs in Cancel/Remind button disabling logic
- Added podspec file

Version 1.7.2

- Added dutch translation
- iRate now displays the StoreKit product view controller correctly even if a modally presented view controller has been displayed

Version 1.7.1

- Fixed deprecation warning when targeting iOS6 as the base target
- Added iRateDidPresentStoreKitModal and iRateDidDismissStoreKitModal delegate methods
- Added additional error logging if StoreKit fails to load product info
- Added Ukranian translation

Version 1.7

- On iOS 6, iRate can now use the StoreKit APIs to display the product page directly within the app.
- iRate now requires the StoreKit framework on iOS
- iRate now requires ARC. To use iRate in a non-ARC project, follow the instructions in the README file.
- Dropped support for 32-bit Macs running Snow Leopard
- Added Swedish translation

Version 1.6.2

- Fixed broken ratings URL (Apple changed it)
- Added Danish translation

Version 1.6.1

- Fixed typo in Italian strings file

Version 1.6

- Added new localisation system (see README for details)
- Added usesPerWeekForPrompt setting
- Fixed deprecation warning in iOS 6
- Improved Spanish translation
- Improved German translation

Version 1.5.3

- Corrected minor spelling mistake in German translation

Version 1.5.2

- Restored App Store deep link on iOS6 (didn't work in beta, but now does)
- Added promptAgainForEachNewVersion option to enable/disable prompting each time the app is updated
- Added verboseLogging option to make it easier to diagnose why a new version isn't being correctly detected
- Renamed debug property to previewMode as this better describes its function
- Add Simplified Chinese localisation

Version 1.5.1

- Fixed crash on iOS 4.x and Mac OS 10.6.x when compiled using Xcode 4.4

Version 1.5

- Added support for iOS6. Currently it does not appear to be possible to take users directly to the ratings page on iOS6, but iRate will now at least open the app store on the app page without an error.
- Fixed bug in the app store country selection logic
- Changed appStoreGenre to appStoreGenreID, as this is not locale-specific

Version 1.4.9

- Added support for sandboxed Mac App Store apps with no network access
- Updated ARC Helper library

Version 1.4.8

- Added explicit 60-second timeout for connectivity check
- iRate will now no longer spawn multiple download threads if closed and re-opened whilst performing a check
- Added Portuguese translation

Version 1.4.7

- Fixed a bug where advanced properties set in the delegate methods might be subsequently overridden by iRate
- Added Events Demo example

Version 1.4.6

- Fixed odd glitch where shaking device would cause UIAlertview to slowly shrink
- Added disableAlertViewResizing option (see README for details)
- Added Resizing Disabled example project
- Added Korean translation

Version 1.4.5

- Improved German, Spanish, Japanese, Russian and Polish translations
- Added onlyPromptIfMainWindowIsAvailable option

Version 1.4.4

- Added Turkish localisation
- Improved German translation
- Fixed alert layout for long app names

Version 1.4.3

- It is now possible again to use debug to test the iRate message for apps that are not yet on the App Store. 

Version 1.4.2

- Added Hebrew localisation
- Fixed issue with UIAlertView label resizing
- Fixed some compiler warnings

Version 1.4.1

- Added logic to prevent UIAlertView collapsing in landscape mode
- Added Russian, Polish and Traditional Chinese localisations
- Improved Japanese localisation
- Now handles nil cancel button text correctly

Version 1.4

- Included localisation for French, German, Italian, Spanish and Japanese
- iRate is now *completely zero-config* in most cases!
- It is no longer necessary to set the app store ID in most cases
- iRate default text now uses "playing" instead of "using" for games
- iRate delegate now defaults to App Delegate unless otherwise specified
- By default, iRate no longer prompts the user to rate the app unless they are running the latest version

Version 1.3.5

- Fixed bug introduced in 1.3.4 where remind button would not appear on iOS

Version 1.3.4

- Fixed compiler warning
- Added `iRateDidDetectAppUpdate` delegate method
- Added ARC Test example

Version 1.3.3

- Added missing ivar required for 32-bit Mac OS builds.

Version 1.3.2

- Added logic to prevent multiple prompts from being displayed if user fails to close one prompt before the next is due to be opened.
- Added workaround for change in UIApplicationWillEnterForegroundNotification implementation in iOS5

Version 1.3.1

- Added automatic support for ARC compile targets
- Now requires Apple LLVM 3.0 compiler target

Version 1.3

- Added additional delegate methods to facilitate logging
- Renamed disabled property to promptAtLaunch for clarity

Version 1.2.3

- iRate now uses CFBundleDisplayName for the application name (if available) 
- Reorganised examples

Version 1.2.2

- Fixed misspelled delegate method
- Fixed bug in advanced Mac project where rating prompt was displayed automatically even if button was not pressed
- Removed unneeded project files

Version 1.2.1

- Exposed the shouldPromptForRating method to make it easier to control when rating prompt is displayed
- Increased `MAC_APP_STORE_REFRESH_DELAY` to 5 seconds to support older machines

Version 1.2

- Added delegate and additional accessor properties for custom behaviour
- Added advanced example project to demonstrate use of the delegate protocol

Version 1.1

- Now compatible with iOS 3.x
- Fixed incorrect iPhone review URL

Version 1.0

- Initial release.