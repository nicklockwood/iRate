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