//
//  NXTDevice.h
//  MINDcode
//
//  Created by Tim Gleue on 13.09.15.
//  Copyright (c) 2015 Jeff Sawatzky. All rights reserved.
//

#import <NXTKit/NXTKit.h>

extern NSString * const kNXTDeviceDidChangeNotification;

@interface NXTDevice : MRNXTDevice

@property (nonatomic, readonly) NSString *deviceName;
@property (nonatomic, readonly) NSInteger freeSpace;
@property (nonatomic, readonly) NSInteger batteryLevel;

- (void)update;

@end
