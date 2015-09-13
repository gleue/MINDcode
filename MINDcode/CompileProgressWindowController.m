//
//  CompilingProgressWindowController.m
//  MINDcode
//
//  Created by Jeff Sawatzky on 2013-01-17.
//  Copyright (c) 2013 Jeff Sawatzky. All rights reserved.
//

#import "CompileProgressWindowController.h"
#import "ProgressWindowController+Protected.h"

@interface CompileProgressWindowController ()

@property (nonatomic, strong) SourceCompiler * compiler;
@property (nonatomic, strong) NSURL * destinationURL;
@property (nonatomic, assign) BOOL result;

@end


@implementation CompileProgressWindowController

- (id)initWithDocument:(SourceDocument *)document {
	self = [super init];
    
	if (self) {
        self.compiler = [document createSourceCompiler];
        self.compiler.delegate = self;
	}
    
	return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    self.progressIndictor.indeterminate = YES;
    self.promptTextField.stringValue =
    [NSString stringWithFormat:NSLocalizedString(@"CompileProgressWindowControllerMessageFormat", nil)];
    
    [self performSelector:@selector(prepareForCompile) withObject:self afterDelay:0];
}

- (void)prepareForCompile {
    [self compile];
}

- (void)compile {

    [self.progressIndictor startAnimation:nil];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ (void) {
        self.result = [self.compiler compile];
        self.destinationURL = nil;
        if (self.result) {
            self.destinationURL = self.compiler.destinationURL;
        }
        dispatch_async(dispatch_get_main_queue(), ^ (void) {
            
            [self.progressIndictor stopAnimation:nil];
            [self dismissSheet];
        });
    });
}

- (void)cancel {
    
    [self.progressIndictor stopAnimation:nil];

    [self.compiler kill];
    self.result = NO;
    
    [super cancel];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    
    [super didEndSheet:sheet returnCode:returnCode contextInfo:contextInfo];

    if (returnCode == NSModalResponseCancel) {
        
        [self.delegate compileProgressWindowControllerDidCancel:self];

    } else {
    
        [self.delegate compileProgressWindowController:self didFinishCompilingFile:self.destinationURL withSuccess:self.result];
    }
}

#pragma mark Source Compiler Delegate

- (void)sourceCompiler:(SourceCompiler *)sourceCompiler didReceiveOutput:(NSString *)output {

    dispatch_async(dispatch_get_main_queue(), ^ (void) {
        [self.delegate compileProgressWindowController:self didReceiveOutput:output];
    });
}

@end