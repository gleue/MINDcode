//
//  ProgressWindowController.h
//  MINDcode
//
//  Created by Jeff Sawatzky on 2013-01-14.
//  Copyright (c) 2013 Jeff Sawatzky. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ProgressWindowController : NSWindowController

- (void)presentAsSheetInWindow:(NSWindow *)parentWindow;
- (void)dismissSheet;

- (void)cancel;

@end