//
//  ProgressWindowController.m
//  MINDcode
//
//  Created by Jeff Sawatzky on 2013-01-14.
//  Copyright (c) 2013 Jeff Sawatzky. All rights reserved.
//

#import "ProgressWindowController+Protected.h"

@interface ProgressWindowController ()

@end


@implementation ProgressWindowController

- (id)init {
    self = [super initWithWindowNibName:@"ProgressWindowController"];
    
    if (self) {
    }
    
	return self;
}

- (void)presentAsSheetInWindow:(NSWindow *)parentWindow {

    [NSApp beginSheet: self.window
       modalForWindow: parentWindow
        modalDelegate: self
       didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
          contextInfo: nil];
}

- (void)dismissSheet {
    
	[NSApp endSheet:self.window];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {

    [sheet orderOut:self];
}

- (void)cancel {

    [NSApp endSheet:self.window returnCode:NSModalResponseCancel];
}

- (IBAction)cancel:(id)sender {
    
    [self cancel];
}

@end