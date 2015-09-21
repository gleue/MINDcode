//
//  MainViewController.m
//  MINDcode
//
//  Created by Jeff Sawatzky on 2013-01-14.
//  Copyright (c) 2013 Jeff Sawatzky. All rights reserved.
//

#import "MainViewController.h"
#import "ACEViewController.h"
#import "UploadProgressWindowController.h"

#import <NXTKit/NXTKit.h>
#import <NXTUtils/NXTUtils.h>

@interface MainViewController()

@property (strong) IBOutlet NSView * nxtInfoDisconnectedView;
@property (strong) IBOutlet NSView * nxtInfoBoxConnectedView;
@property (strong) IBOutlet NSTextField *nxtInfoBoxDevicenameLabel;
@property (strong) IBOutlet NSLevelIndicatorCell *nxtInfoBoxFreespaceIndicator;

@property (strong) IBOutlet ACEViewController * aceViewController;
@property (strong) IBOutlet NSView * aceView;
@property (strong) IBOutlet NSProgressIndicator * compileProgressIndicator;
@property (strong) IBOutlet NSProgressIndicator * connectProgessIndicator;
@property (strong) IBOutlet NSBox * nxtInfoBoxView;
@property (strong) IBOutlet NSTextView * outputTextView;

@property (strong) ProgressWindowController * currentProgressController;
@property (assign) BOOL shouldUploadAfterCompile;
@property (assign) BOOL shouldRunAfterUpload;

- (IBAction)compileWasClicked:(id)sender;
- (IBAction)clearOutputWasClicked:(id)sender;
- (IBAction)connectToNXTDeviceWasClicked:(id)sender;
- (IBAction)uploadToNXTDeviceWasClicked:(id)sender;
- (IBAction)runToNXTDeviceWasClicked:(id)sender;
- (IBAction)stopProgramOnNXTDeviceWasClicked:(id)sender;

@end

@implementation MainViewController

-(void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)loadView {

    [super loadView];
    
    [self.compileProgressIndicator stopAnimation:self];
    [self.connectProgessIndicator stopAnimation:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nxtDeviceManagerDidOpenDeviceNotification:)
                                                 name:kNXTDeviceManagerDidOpenDeviceNotification
                                               object:[NXTDeviceManager defaultManager]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nxtDeviceManagerDidFailToOpenDeviceNotification:)
                                                 name:kNXTDeviceManagerDidFailToOpenDeviceNotification
                                               object:[NXTDeviceManager defaultManager]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nxtDeviceManagerDidCloseDeviceNotification:)
                                                 name:kNXTDeviceManagerDidCloseDeviceNotification
                                               object:[NXTDeviceManager defaultManager]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nxtDeviceDidChangeNotification:)
                                                 name:kNXTDeviceDidChangeNotification
                                               object:nil];

    [self updateDeviceInfo];

    if ([[NXTDeviceManager defaultManager] isConnected]) {
        [self setCurrentNXTInfoBoxView:self.nxtInfoBoxConnectedView];
    } else {
        [self setCurrentNXTInfoBoxView:self.nxtInfoDisconnectedView];
    }
    
    self.aceViewController.sourceDocument = self.sourceDocument;
    [self.aceViewController.view setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
    [self.aceViewController.view setFrame:[self.aceView bounds]];
    [self.aceView addSubview:self.aceViewController.view];
}

- (void) setCurrentNXTInfoBoxView:(NSView *)view {
    // First remove all current subviews of the nxt info box
    [self.nxtInfoBoxConnectedView removeFromSuperview];
    [self.nxtInfoDisconnectedView removeFromSuperview];
    
    // Now set the given view as the subview
    [view setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
    [view setFrame:[self.nxtInfoBoxView bounds]];
    [self.nxtInfoBoxView addSubview:view];
}

- (void) appendStringToOutputTextView:(NSString *)string {
    NSAttributedString * astring = [[NSAttributedString alloc] initWithString:string];
	NSTextStorage * storage = [self.outputTextView textStorage];
    
    // Append string to textview
    [storage beginEditing];
    [storage appendAttributedString:astring];
	[storage endEditing];
    
    // Smart Scrolling
    NSRange range = NSMakeRange([[self.outputTextView string] length], 0);
    [self.outputTextView scrollRangeToVisible: range];
}

- (void) compileAndUpload:(BOOL)upload andRun:(BOOL)run {
    [self.outputTextView setString:@""];
     
    [self.sourceDocument saveDocument:self];
    if (self.sourceDocument.fileURL && NO == self.sourceDocument.isDocumentEdited) {        
        [self appendStringToOutputTextView:NSLocalizedString(@"MainViewControllerCompiling", nil)];
        [self.compileProgressIndicator startAnimation:self];
        
        self.shouldUploadAfterCompile = upload;
        self.shouldRunAfterUpload = run;
        
        CompileProgressWindowController * cpwc = [[CompileProgressWindowController alloc] initWithDocument:self.sourceDocument];
        cpwc.delegate = self;
        self.currentProgressController = cpwc;
        [cpwc presentAsSheetInWindow:self.view.window];
    }
}

#pragma mark - Compile Progress Window Controller Delegate

- (void)compileProgressWindowControllerDidCancel:(CompileProgressWindowController *)controller {
    
    self.currentProgressController = nil;
    [self.compileProgressIndicator stopAnimation:self];

    self.shouldUploadAfterCompile = NO;

    [self appendStringToOutputTextView:NSLocalizedString(@"MainViewControllerCompilingCancelled", nil)];
}

- (void)compileProgressWindowController:(CompileProgressWindowController *)controller didReceiveOutput:(NSString *)output {
    
    if (self.currentProgressController) {
        [self appendStringToOutputTextView:output];
    }
}

- (void)compileProgressWindowController:(CompileProgressWindowController *)controller didFinishCompilingFile:(NSURL *)destinationURL withSuccess:(BOOL)success {
    
    self.currentProgressController = nil;
    [self.compileProgressIndicator stopAnimation:self];
    
    if (success) {
        [self appendStringToOutputTextView:NSLocalizedString(@"MainViewControllerCompilingDone", nil)];
        if (self.shouldUploadAfterCompile) {
            self.shouldUploadAfterCompile = NO;
            
            [self appendStringToOutputTextView:NSLocalizedString(@"MainViewControllerUploading", nil)];
            
            UploadProgressWindowController * upwc = [[UploadProgressWindowController alloc] initWithSourceURL:destinationURL device:[NXTDeviceManager defaultManager].device];
            upwc.delegate = self;
            self.currentProgressController = upwc;
            [upwc presentAsSheetInWindow:self.view.window];
        }
    } else {
        [self appendStringToOutputTextView:NSLocalizedString(@"MainViewControllerCompilingFailed", nil)];
    }
}

#pragma mark - Upload Progress Window Controller Delegate

- (void)uploadProgressWindowController:(UploadProgressWindowController *)controller didFinishUploadingFile:(NSString *)fileName withSuccess:(BOOL)success {
    
    self.currentProgressController = nil;
    
    if (success) {
        [self appendStringToOutputTextView:NSLocalizedString(@"MainViewControllerUploadingDone", nil)];
        if (self.shouldRunAfterUpload) {
            self.shouldRunAfterUpload = NO;
            
            [self appendStringToOutputTextView:NSLocalizedString(@"MainViewControllerRunning", nil)];
            
            MRNXTStartProgramCommand * spc = [[MRNXTStartProgramCommand alloc] init];
            spc.filename = fileName;
            
            [[NXTDeviceManager defaultManager].device enqueueCommand:spc responseBlock:NULL];
        }
    } else {
        [self appendStringToOutputTextView:NSLocalizedString(@"MainViewControllerUploadingFailed", nil)];
    }
}

#pragma mark - NXT Device Manager Notifications

- (void)nxtDeviceManagerDidOpenDeviceNotification:(NSNotification *)notification {
    
    [self.connectProgessIndicator stopAnimation:self];
    [self setCurrentNXTInfoBoxView:self.nxtInfoBoxConnectedView];
}

- (void)nxtDeviceManagerDidFailToOpenDeviceNotification:(NSNotification *)notification {
    
    [self.connectProgessIndicator stopAnimation:self];
    [self setCurrentNXTInfoBoxView:self.nxtInfoDisconnectedView];
    
    NSError *error = [notification.userInfo objectForKey:@"error"];
    
    if (error) {
        NSBeginAlertSheet(nil, nil, nil, nil, self.view.window, self, NULL, NULL, nil, @"%@", error.description);
    }
}

- (void)nxtDeviceManagerDidCloseDeviceNotification:(NSNotification *)notification {
    
    [self.connectProgessIndicator stopAnimation:self];
    [self setCurrentNXTInfoBoxView:self.nxtInfoDisconnectedView];
    
    if (self.currentProgressController) {
        [self.currentProgressController dismissSheet];
    }
}

#pragma mark - NXT Device Notifications

- (void)nxtDeviceDidChangeNotification:(NSNotification *)notification {
    
    [self updateDeviceInfo];
}

#pragma mark - Actions

- (IBAction)compileWasClicked:(id)sender {
    [self compileAndUpload:NO andRun:NO];
}

- (IBAction)clearOutputWasClicked:(id)sender {
    [self.outputTextView setString:@""];
}

- (IBAction)connectToNXTDeviceWasClicked:(id)sender {
    [self.connectProgessIndicator startAnimation:self];
    [[NXTDeviceManager defaultManager] connect];
}

- (IBAction)uploadToNXTDeviceWasClicked:(id)sender {
    [self compileAndUpload:YES andRun:NO];
}

- (IBAction)runToNXTDeviceWasClicked:(id)sender {
    [self compileAndUpload:YES andRun:YES];
}

- (IBAction)stopProgramOnNXTDeviceWasClicked:(id)sender {
    
    MRNXTStopProgramCommand * spc = [[MRNXTStopProgramCommand alloc] init];
    
    [[NXTDeviceManager defaultManager].device enqueueCommand:spc responseBlock:^ (id response) {
        
        [self appendStringToOutputTextView:NSLocalizedString(@"MainViewControllerRunningStopped", nil)];
    }];
}

#pragma mark - Helpers

- (void)updateDeviceInfo {

    NXTDevice *device = [NXTDeviceManager defaultManager].device;
    
    if (device) {
        
        self.nxtInfoBoxDevicenameLabel.stringValue = device.deviceName;
        self.nxtInfoBoxFreespaceIndicator.integerValue = device.freeSpace;
        self.nxtInfoBoxFreespaceIndicator.enabled = YES;

    } else {
        
        self.nxtInfoBoxDevicenameLabel.stringValue = NSLocalizedString(@"MainViewControllerUnknownDeviceName", nil);
        self.nxtInfoBoxFreespaceIndicator.enabled = NO;
    }
}

@end