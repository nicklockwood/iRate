//
//  iRateMacAppDelegate.h
//  iRateMac
//
//  Created by Nick Lockwood on 06/02/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iRate.h"


@interface iRateMacAppDelegate : NSObject <NSApplicationDelegate, iRateDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSTextField *label;

- (IBAction)promptForRating:(id)sender;

@end
