//
//  iRateMacAppDelegate.h
//  iRateMac
//
//  Created by Nick Lockwood on 04/02/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface iRateMacAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
