Purpose
--------------

iRate is a library to help you promote your iPhone and Mac App Store apps by prompting users to rate the app after using it for a few days. This approach is one of the best ways to get positive app reviews by targeting only regular users (who presumably like the app or they wouldn't keep using it!).


Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 5.1 / Mac OS 10.8 (Xcode 4.4, Apple LLVM compiler 4.0)
* Earliest supported deployment target - iOS 4.3 / Mac OS 10.7
* Earliest compatible deployment target - iOS 3.0 / Mac OS 10.6

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this OS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

iRate makes use of the ARC Helper library to automatically work with both ARC and non-ARC projects through conditional compilation. There is no need to exclude iRate files from the ARC validation process, or to convert iRate using the ARC conversion tool.


Thread Safety
--------------

iRate uses threading internally to avoid blocking the UI, but none of the iRate external interfaces are thread safe and you should not call any methods or set any properties on iRate except from the main thread.


Installation
--------------

To install iRate into your app, drag the iRate.h, .m and .bundle files into your project. You can omit the .bundle if you are not interested in localised copy.

As of version 1.4, iRate typically requires no configuration at all and will simply run automatically, using the Application's bundle ID to look the app ID up on the App Store.

**Note:** If you have apps with matching bundle IDs on both the Mac and iOS app stores (even if they use different capitalisation), the lookup mechanism won't work, so you'll need to manually set the appStoreID property, which is a numeric ID that can be found in iTunes Connect after you set up an app. Also, if you are creating a sandboxed Mac app and your app does not request the network access permission then you will need to set the appStoreID because it cannot be retrieved from the iTunes service. 

If you do wish to customise iRate, the best time to do this is *before* the app has finished launching. The easiest way to do this is to add the iRate configuration code in your AppDelegate's `initialize` method, like this:

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

For some apps, launches are not a good metric for usage. For example the app might be a daemon that runs constantly, or a game where the user can't write an informed review until they've reached a particular level. In this case you can manually log significant events and have the prompt appear after a predetermined number of these events. Like the usesUntilPrompt setting, the prompt will appear only after the specified number of days AND events, however once the day threshold is reached, the prompt will appear if either the event threshold OR uses threshold is reached. This defaults to 10 events.

    @property (nonatomic, assign) float remindPeriod;

How long the app should wait before reminding a user to rate after they select the "remind me later" option (measured in days). A value of zero means the app will remind the user next launch. Note that this value supersedes the other criteria, so the app won't prompt for a rating during the reminder period, even if a new version is released in the meantime.  This defaults to 1 day.

    @property (nonatomic, copy) NSString *messageTitle;

The title displayed for the rating prompt.

    @property (nonatomic, copy) NSString *message;

The rating prompt message. This should be polite and courteous, but not too wordy.

    @property (nonatomic, copy) NSString *cancelButtonLabel;

The button label for the button to dismiss the rating prompt without rating the app.

    @property (nonatomic, copy) NSString *rateButtonLabel;

The button label for the button the user presses if they do want to rate the app.

    @property (nonatomic, copy) NSString *remindButtonLabel;

The button label for the button the user presses if they don't want to rate the app immediately, but do want to be reminded about it in future. Set this to nil if you don't want to display the remind me button - e.g. if you don't have space on screen.

    @property (nonatomic, assign) BOOL disableAlertViewResizing;

On iOS, iRate includes some logic to resize the alert view to ensure that your rating message is visible in both portrait and landscape mode, and that it doesn't scroll or become truncated. The code to do this is a rather nasty hack, so if your alert text is very short and/or your app only needs to function in portrait mode on iPhone, you may wish to set this property to YES, which may help make your app more robust against future iOS updates. Try the *Resizing Disabled* example for a demonstration of the effect.

    @property (nonatomic, assign) BOOL onlyPromptIfLatestVersion;

Set this to NO to enabled the rating prompt to be displayed even if the user is not running the latest version of the app. This defaults to YES because that way users won't leave bad reviews due to bugs that you've already fixed, etc.

    @property (nonatomic, assign) BOOL onlyPromptIfMainWindowIsAvailable;

This setting is applicable to Mac OS only. By default, on Mac OS the iRate alert is displayed as sheet on the main window. Some applications do not have a main window, so this approach doesn't work. For such applications, set this property to NO to allow the iRate alert to be displayed as a regular modal window.

    @property (nonatomic, assign) BOOL promptAtLaunch;

Set this to NO to disable the rating prompt appearing automatically when the application launches or returns from the background. The rating criteria will continue to be tracked, but the prompt will not be displayed automatically while this setting is in effect. You can use this option if you wish to manually control display of the rating prompt.

    @property (nonatomic, assign) BOOL debug;

If set to YES, iRate will always display the rating prompt on launch, regardless of how long the app has been in use or whether it's the latest version. Use this to proofread your message and check your configuration is correct during testing, but disable it for the final release (defaults to NO).


Advanced properties
--------------

If the default iRate behaviour doesn't meet your requirements, you can implement your own by using the advanced properties, methods and delegate. The properties below let you access internal state and override it:

    @property (nonatomic, strong) NSURL *ratingsURL;

The URL that the app will direct the user to so they can write a rating for the app. This is set to the correct value for the given platform automatically. On iOS 5 and below this takes users directly to the ratings page, but on iOS 6 and Mac OS it takes users to the main app page (if there is a way to directly link to the ratings page on those platforms, I've yet to find it). If you are implementing your own rating prompt, you should probably use the `openRatingsPageInAppStore` method instead, especially on Mac OS, as the process for opening the Mac app store is more complex than merely opening the URL.

    @property (nonatomic, strong) NSDate *firstUsed;

The first date on which the user launched the current version of the app. This is used to calculate whether the daysUntilPrompt criterion has been met.

    @property (nonatomic, strong) NSDate *lastReminded;

The date on which the user last requested to be reminded of an update.

    @property (nonatomic, assign) NSUInteger usesCount;

The number of times the current version of the app has been used (launched).

    @property (nonatomic, assign) NSUInteger eventCount;

The number of significant application events that have been recorded since the current version was installed. This is incremented by the logEvent method, but can also be manipulated directly. Check out the *Events Demo* to see how this os used. 

    @property (nonatomic, assign) BOOL declinedThisVersion;

This flag indicates whether the user has declined to rate the current version (YES) or not (NO).

    @property (nonatomic, assign) BOOL ratedThisVersion;

This flag indicates whether the user has already rated the current version (YES) or not (NO).

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

This method skips the user alert and opens the application ratings page in the Mac or iPhone app store, depending on which platform is running. This method does not perform any checks to verify that the machine has network access or that the app store is available. It also does not call any delegate methods. You should use this method instead of the ratingsURL property if you are running on Mac OS as the process for launching the Mac app store is more complex than merely opening the URL. Note that this method depends on the `appStoreID` which is only retrieved after polling the iTunes server, so if you intend to call this method directly, you will need to set the `appStoreID` property yourself beforehand.


Delegate methods
---------------

The iRateDelegate protocol provides the following methods that can be used intercept iRate events and override the default behaviour. All methods are optional.

    - (void)iRateCouldNotConnectToAppStore:(NSError *)error;

This method is called if iRate cannot connect to the App Store, usually because the network connection is down. This may also fire if your app does not have access to the network due to Sandbox permissions, in which case you will need to manually set the appStoreID so that iRate can still function.

    - (void)iRateDidDetectAppUpdate;

This method is called if iRate detects that the application has been updated since the last time it was launched.

    - (BOOL)iRateShouldShouldPromptForRating;

This method is called immediately before the rating prompt is displayed to the user. You can use this method to block the standard prompt alert and display the rating prompt in a different way, or bypass it altogether.

    - (void)iRateUserDidAttemptToRateApp;
    
This is called when the user pressed the rate button in the rating prompt. This is useful if you want to log user interaction with iRate. This method is only called if you are using the standard iRate alert view prompt and will not be called automatically if you provide a custom rating implementation or call the `openRatingsPageInAppStore` method directly.
    
    - (void)iRateUserDidDeclineToRateApp;
    
This is called when the user declines to rate the app. This is useful if you want to log user interaction with iRate. This method is only called if you are using the standard iRate alert view prompt and will not be called automatically if you provide a custom rating implementation.
    
    - (void)iRateUserDidRequestReminderToRateApp;

This is called when the user asks to be reminded to rate the app. This is useful if you want to log user interaction with iRate. This method is only called if you are using the standard iRate alert view prompt and will not be called automatically if you provide a custom rating implementation.


Localisation
---------------

The defaults strings for iRate are already localised for English, French, German, Italian, Spanish, Japanese, Traditional Chinese, Russian, Polish and Hebrew.

It is not recommended that you modify the strings files in the iRate.bundle, as it will complicate updating to newer versions of iRate. If you do want to edit the files, or open them so you can copy the keys into your own strings file, you should note that the iRate strings files have actually been compiled as binary plists, so you'll need to open them in Xcode and use the Open As > Property List option, or they will appear as gibberish.

If you want to add an additional language, or replace all the built-in strings, the simplest option is to remove the iRate.bundle from your project and then add the iRate keys directly to your own Localizable.strings file.

If you want to override some of the localised strings but leave the others intact, you can provide localised values for any or all of the message strings by setting the keys directly in code using NSLocalizedString(...), e.g.

    + (void)initialize
    {
        [iRate sharedInstance].messageTitle = NSLocalizedString(@"Rate MyApp", @"iRate message title");
        [iRate sharedInstance].message = NSLocalizedString(@"If you like MyApp, please take the time, etc", @"iRate message");
        [iRate sharedInstance].cancelButtonLabel = NSLocalizedString(@"No, Thanks", @"iRate decline button");
        [iRate sharedInstance].remindButtonLabel = NSLocalizedString(@"Remind Me Later", @"iRate remind button");
        [iRate sharedInstance].rateButtonLabel = NSLocalizedString(@"Rate It Now", @"iRate accept button");
    }


Example Projects
---------------

When you build and run the basic Mac or iPhone example project for the first time, it will show an alert asking you to rate the app. This is because the debug option is set.

Disable the debug option and play with the other settings to see how the app behaves in practice.


Advanced Example
---------------

The advanced example demonstrates how you might implement a completely bespoke iRate interface using the iRateDelegate methods. Automatic prompting is disabled and instead the user can opt to rate the app by pressing the "Rate this app" button.

When pressed, the app first checks that the app store is available (it may not be if the computer has no Internet connection or apple.com is down), and then launches the Mac App Store.

The example is for Mac OS, but the same thing can be applied on iOS.
