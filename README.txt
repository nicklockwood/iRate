Purpose
--------------

iRate is a library to help you promote your iPhone and Mac App Store apps by prompting users to rate the app after using it for a few days. This approach is one of the best ways to get positive app reviews by targeting only regular users (who presumably like the app or they wouldn't keep using it!) and is actually recommended by Apple in their App Store tips page:

http://developer.apple.com/news/ios/appstoretips/


Installation
--------------

To install iRate into your app, drag the iRate.h and .m files into your project.

To enable iRate in your application you need to instantiate and configure iRate *before* the app has finished launching. The easiest way to do this is to add the iRate configuration code in your AppDelegate's initialize method, like this:

+ (void)initialize
{
	//configure iRate
	[iRate sharedInstance].appStoreID = 355313284;
}

The above code represents the minimum configuration needed to make iRate work, although there are other configuration options you may wish to add (documented below).

The exact same configuration code will work for both Mac and iPhone/iPad.


Configuration
--------------

To configure iRate, there are a number of properties of the iRate class that can alter the behaviour and appearance of iRate. These should be mostly self- explanatory, but they are documented below:

appStoreID - This should match the iTunes app ID of your application, which you can get from iTunes connect after setting up your app. This is the only compulsory setting - everything else can be left as default if you like.

applicationName - This is the name of the app displayed in the iRate alert. It is set automatically from the application's info.plist, but you may wish to override it with a shorter or longer version.

daysUntilPrompt - This is the number of days the user must have had the app installed before they are prompted to rate it. The time is measured from the first time the app is launched. This is a floating point value, so it can be used to specify a fractional number of days (e.g. 0.5). The default value is 10 days.

usesUntilPrompt - This is the minimum number of times the user must launch the app before they are prompted to rate it. This avoids the scenario where a user runs the app once, doesn't look at it for weeks and then launches it again, only to be immediately prompted to rate it. The minimum use count ensures that only frequent users are prompted. The prompt will appear only after the specified number of days AND uses has been reached. This defaults to 10 uses.

eventsUntilPrompt - For some apps, launches are not a good metric for usage. For example the app might be a daemon that runs constantly, or a game where the user can't write an informed review until they've reached a particular level. In this case you can manually log significant events and have the prompt appear after a predetermined number of these events. Like the usesUntilPrompt setting, the prompt will appear only after the specified number of days AND events, however once the day threshold is reached, the prompt will appear if either the event threshold OR uses threshold is reached. This defaults to 10 events.

remindPeriod - How long the app should wait before reminding a user to rate after they select the "remind me later" option. A value of zero means the app will remind the user next launch. Note that this value supersedes the other criteria, so the app won't prompt for a rating during the reminder period, even if a new version is released in the meantime.  This defaults to 1 day.

messageTitle - The title displayed for the rating prompt.

message - The rating prompt message. This should be polite and courteous, but not too wordy.

cancelButtonLabel - The button label for the button to dismiss the rating prompt without rating the app.

rateButtonLabel - The button label for the button the user presses if they do want to rate the app.

remindButtonLabel - The button label for the button the user presses if they don't want to rate the app immediately, but do want to be reminded about it in future. Set this to nil if you don't want to display the remind me button - e.g. if you don't have space on screen.

disabled - Set this to YES to disable the rating prompt. The rating criteria will continue to be tracked, but the prompt will not be displayed while this setting is in effect.

debug - If set to YES, iRate will always display the rating prompt on launch, regardless of how long the app has been in use. Use this to proofread your message and check your configuration is correct during testing, but disable it for the final release.


Advanced properties
--------------

If the default iRate behaviour doesn't meet your requirements, you can implement your own by using the advanced properties, methods and delegate. The properties below let you access internal state and override it:

ratingsURL - The URL that the app will direct the user to so they can write a rating for the app. If you are implementing your own rating prompt, you should probably use the openRatingsPageInAppStore method instead, especially on Mac OS, as the process for opening the Mac app store is more complex than merely opening the URL.

firstUsed - The first date on which the user launched the current version of the app. This is used to calculate whether the daysUntilPrompt criterion has been met.

lastReminded - The date on which the user last requested to be reminded of an update.

usesCount - The number of times the current version of the app has been used (launched).

eventCount - The number of significant application events that have been recorded since the current version was installed. This is incremented by the logEvent method, but can also be manipulated directly.

declinedThisVersion - This flag indicates whether the user has declined to rate the current version (YES) or not (NO).

ratedThisVersion - This flag indicates whether the user has already rated the current version (YES) or not (NO).

delegate - An object you have supplied that implements the iRateDelegate protocol, documented below. Use this to detect and/or override iRate's default behaviour. 


Methods
--------------

Besides configuration, iRate has the following methods:

- (void)logEvent:(BOOL)deferPrompt;

This method can be called from anywhere in your app (after iRate has been configured) and increments the iRate significant event count. When the predefined number of events is reached the rating prompt will be shown. The optional deferPrompt parameter is used to determine if the prompt will be shown immediately (NO) or if the app will wait until the next launch (YES).

- (void)promptForRating;

This method will immediately trigger the rating prompt without checking that the  app store is available, and without calling the iRateShouldShouldPromptForRating delegate method.

- (void)promptIfNetworkAvailable;

This method will check if the app store is available, and if it is, it will display the rating prompt to the user. The iRateShouldPromptForRating delegate method will be called before the alert is shown, so you can intercept it.

- (void)openRatingsPageInAppStore;

This method skips the user alert and opens the App Store immediately. This method does not perform any checks to verify that the machine has network access or that the app store is available. It also does not call any delegate methods.


Delegate methods
---------------

The iRateDelegate protocol provides the following methods that can be used intercept iRate events and override the default behaviour. All methods are optional.

- (void)iRateCouldNotConnectToAppStore:(NSError *)error;

This method is called if iRate cannot connect to the App Store, usually because the network connection is down.

- (BOOL)iRateShouldShouldPromptForRating;

This method is called immediately before the rating prompt is displayed to the user. You can use this method to block the standard prompt alert and display the rating prompt in a different way, or bypass it altogether.


Localisation
---------------

Although iRate isn't localised, it is easy to localise without making any modifications to the library itself. All you need to do is provide localised values for all of the message strings by setting the properties above using NSLocalizedString(...).


Example Projects
---------------

When you build and run the basic Mac or iPhone example project for the first time, it will show an alert asking you to rate the app. This is because the debug option is set.

Disable the debug option and play with the other settings to see how the app behaves in practice.


Advanced Example
---------------

The advanced example demonstrates how you might implement a completely bespoke iRate interface. Automatic prompting is disabled and instead the user can opt to rate the app by pressing the "Rate this app" button.

When pressed, the app first checks that the app store is available (it may not be if the computer has no internet connection or apple.com is down), and then launches the Mac App Store.
