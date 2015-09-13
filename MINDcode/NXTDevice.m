//
//  NXTDevice.m
//  MINDcode
//
//  Created by Tim Gleue on 13.09.15.
//  Copyright (c) 2015 Jeff Sawatzky. All rights reserved.
//

#import "NXTDevice.h"

NSString * const kNXTDeviceDidChangeNotification = @"kNXTDeviceDidChangeNotification";

@implementation NXTDevice

@synthesize deviceName = _deviceName;
@synthesize freeSpace = _freeSpace;

- (instancetype)initWithTransport:(MRDeviceTransport *)aTransport {

    self = [super initWithTransport:aTransport];
    
    if (self) {
    
        _deviceName = nil;
        _freeSpace = -1;
        _batteryLevel = -1;
    }
    
    return self;
}

#pragma mark - Accessors

- (void)setDeviceName:(NSString *)deviceName {

    _deviceName = [deviceName copy];
}

- (void)setFreeSpace:(NSInteger)freeSpace {

    _freeSpace = freeSpace;
}

- (void)setBatteryLevel:(NSInteger)batteryLevel {

    _batteryLevel = batteryLevel;
}

#pragma mark - Methods

- (void)update {

    MRNXTGetDeviceInfoCommand *dic = [[MRNXTGetDeviceInfoCommand alloc] init];
    
    __weak typeof(self) weakSelf = self;
    
    [self enqueueCommand:dic responseBlock:^ (id response) {
        
        MRNXTDeviceInfoResponse *info = response;
        
        if (info.status == 0) {
            
            weakSelf.deviceName = info.brickName;
            weakSelf.freeSpace = info.freeSpace;
            
            dispatch_async(dispatch_get_main_queue(), ^ (void) {

                [[NSNotificationCenter defaultCenter] postNotificationName:kNXTDeviceDidChangeNotification object:self];
            });
        }
    }];
    
    MRNXTGetBatteryLevelCommand *blc = [[MRNXTGetBatteryLevelCommand alloc] init];
    
    [self enqueueCommand:blc responseBlock:^ (id response) {
        
        MRNXTBatteryLevelResponse *lvl = response;
        
        if (lvl.status == 0) {
            
            weakSelf.batteryLevel = lvl.batteryLevel;
            
            dispatch_async(dispatch_get_main_queue(), ^ (void) {
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kNXTDeviceDidChangeNotification object:self];
            });
        }
    }];
}

#pragma mark - MRNXTDevice overwrites

- (void)deviceTransportDidOpen:(MRDeviceTransport *)aTransport {
    
    [super deviceTransportDidOpen:aTransport];

    [self update];
}

- (void)deviceTransportDidClose:(MRDeviceTransport *)aTransport {
    
    [super deviceTransportDidClose:aTransport];

    _deviceName = nil;
    _freeSpace = -1;
    _batteryLevel = -1;
}

@end
