//
//  iRate.h
//  iRate
//
//  Created by Nick Lockwood on 26/01/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>


#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
@interface iRate : NSObject<UIAlertViewDelegate>
#else
@interface iRate : NSObject
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

//log a significant event
- (void)logEvent:(BOOL)deferPrompt;

@end
