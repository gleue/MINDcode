//
//  NXTDeviceManager.m
//  MINDcode
//
//  Created by Jeff Sawatzky on 2013-01-14.
//  Copyright (c) 2013 Jeff Sawatzky. All rights reserved.
//

#import "NXTDeviceManager.h"

NSString *const kNXTDeviceManagerDidOpenDeviceNotification = @"kNXTDeviceManagerDidOpenDeviceNotification";
NSString *const kNXTDeviceManagerDidFailToOpenDeviceNotification = @"kNXTDeviceManagerDidFailToOpenDeviceNotification";
NSString *const kNXTDeviceManagerDidCloseDeviceNotification = @"kNXTDeviceManagerDidCloseDeviceNotification";


@interface NXTDeviceManager()

@property (nonatomic, strong) NXTDevice *device;

@end

@implementation NXTDeviceManager

+ (NXTDeviceManager *)defaultManager {

    static NXTDeviceManager *theInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{

        theInstance = [[NXTDeviceManager alloc] init];
    });

    return theInstance;
}

- (instancetype)init {

    self = [super init];
    
    if (self) {
        
        self.device = nil;
    }
    
    return self;
}

- (BOOL)isConnected {

    return (self.device != nil);
}

- (void)connect {
    
    if (self.device) {

        [self.device close];
        self.device = nil;
    }
    
    MRDeviceTransport *transport = nil;
    
    // First look for NXT devices connected via USB
    NSArray *usbDevices = [MRUSBDeviceEntry matchingDevicesForProductID:0x2 vendorID:0x694];
    
    // If we found some, then use the first one by default
	if ([usbDevices count]) {
        
        // Take the first device. Perhaps in the future we may want to provide a way to select different ones
		MRUSBDeviceEntry *entry = [usbDevices objectAtIndex:0];
		
		NSArray *pipes = [NSArray arrayWithObjects:
						  [MRUSBDevicePipeDescriptor pipeDescriptorWithTransferType:MRUSBTransferTypeBulk
																		  direction:MRUSBTransferDirectionIn],
						  [MRUSBDevicePipeDescriptor pipeDescriptorWithTransferType:MRUSBTransferTypeBulk
																		  direction:MRUSBTransferDirectionOut], nil];
		
		transport = [[MRUSBDeviceTransport alloc] initWithDeviceEntry:entry desiredPipes:pipes];
        
	} else {
        
		IOBluetoothDeviceSelectorController *bluetoothDeviceSelectorController = [IOBluetoothDeviceSelectorController deviceSelector];
        int result = [bluetoothDeviceSelectorController runModal];
        
        if (result == kIOBluetoothUISuccess) {
            
            NSArray *results = [bluetoothDeviceSelectorController getResults];
            
            if ([results count]) {
                IOBluetoothDevice *firstDevice = [results objectAtIndex:0];
                transport = [[MRBluetoothDeviceTransport alloc] initWithBluetoothDevice:firstDevice];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:kNXTDeviceManagerDidCloseDeviceNotification object:self];
            }
            
        } else {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNXTDeviceManagerDidCloseDeviceNotification object:self];
        }
	}
    
    if (transport) {

        NSError *error = nil;
        
        self.device = [[NXTDevice alloc] initWithTransport:transport];
        self.device.delegate = self;
        
        if (![self.device open:&error]) {

            [self.device close];
            self.device = nil;
        }
    }
}

#pragma mark Device Delegate

- (void)deviceDidOpen:(MRDevice *)aDevice {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNXTDeviceManagerDidOpenDeviceNotification object:self];
}

- (void)device:(MRDevice *)aDevice didFailToOpen:(NSError *)error {
    
    [self.device close];
    self.device = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNXTDeviceManagerDidFailToOpenDeviceNotification object:self userInfo:@{@"error":error}];
}

- (void)deviceDidClose:(MRDevice *)aDevice {
    
    [self.device close];
    self.device = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNXTDeviceManagerDidCloseDeviceNotification object:self];
}

@end