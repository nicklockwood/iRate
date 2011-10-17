//
//  iRate.h
//
//  Version 1.2.1
//
//  Created by Nick Lockwood on 26/01/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//
//  Get the latest version of iCarousel from either of these locations:
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

#import <Foundation/Foundation.h>


@protocol iRateDelegate

@optional
- (void)iRateCouldNotConnectToAppStore:(NSError *)error;
- (BOOL)iRateShouldShouldPromptForRating;

@end


@interface iRate : NSObject
#ifdef __i386__
{
	NSUInteger appStoreID;
	NSString *applicationName;
	NSString *applicationVersion;
	NSUInteger usesUntilPrompt;
	NSUInteger eventsUntilPrompt;
	float daysUntilPrompt;
	float remindPeriod;
	NSString *messageTitle;
	NSString *message;
	NSString *cancelButtonLabel;
	NSString *remindButtonLabel;
	NSString *rateButtonLabel;
	NSURL *ratingsURL;
	BOOL disabled;
	BOOL debug;
	id<iRateDelegate> delegate;
}
#endif

+ (iRate *)sharedInstance;

//app-store id - always set this
@property (nonatomic, assign) NSUInteger appStoreID;

//application name - this is set automatically
@property (nonatomic, retain) NSString *applicationName;

//usage settings - these have sensible defaults
@property (nonatomic, assign) NSUInteger usesUntilPrompt;
@property (nonatomic, assign) NSUInteger eventsUntilPrompt;
@property (nonatomic, assign) float daysUntilPrompt;
@property (nonatomic, assign) float remindPeriod;

//message text, you may wish to customise these, e.g. for localisation
@property (nonatomic, retain) NSString *messageTitle;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) NSString *cancelButtonLabel;
@property (nonatomic, retain) NSString *remindButtonLabel;
@property (nonatomic, retain) NSString *rateButtonLabel;

//debugging and disabling
@property (nonatomic, assign) BOOL disabled;
@property (nonatomic, assign) BOOL debug;

//advanced properties for implementing custom behaviour
@property (nonatomic, retain) NSURL *ratingsURL;
@property (nonatomic, retain) NSDate *firstUsed;
@property (nonatomic, retain) NSDate *lastReminded;
@property (nonatomic, assign) NSUInteger usesCount;
@property (nonatomic, assign) NSUInteger eventCount;
@property (nonatomic, assign) BOOL declinedThisVersion;
@property (nonatomic, assign) BOOL ratedThisVersion;
@property (nonatomic, assign) id<iRateDelegate> delegate;

//manually control behaviour
- (BOOL)shouldPromptForRating;
- (void)promptForRating;
- (void)promptIfNetworkAvailable;
- (void)openRatingsPageInAppStore;
- (void)logEvent:(BOOL)deferPrompt;

@end
