//
//  FSBLEUtilities.m
//  SLFarseer_iOS
//
//  Created by Go Salo on 2/23/15.
//  Copyright (c) 2015 Qeekers. All rights reserved.
//

#import "FSBLEUtilities.h"
#import "FSBLEDefine.h"
#import "FSDefine.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIDevice.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#endif

@implementation FSBLEUtilities

+ (NSData *)getPeripheralInfoData {
    Byte OSType;
    NSString *OSVersion;
    NSString *deviceType;
    NSString *deviceName;
    NSString *bundleName;
    
#if TARGET_OS_IPHONE
    UIDevice *device = [UIDevice currentDevice];
    OSType = BLEOSTypeIOS;
    OSVersion = device.systemVersion;
    deviceType = device.model;
    deviceName = device.name;
#elif TARGET_OS_MAC
    NSDictionary *systemVersionDictionary = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    OSVersion = systemVersionDictionary[@"ProductVersion"];

    deviceName = [NSHost currentHost].localizedName;
    OSType = BLEOSTypeOSX;
    
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    if (len) {
        char *model = (char *)malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        deviceType = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
        free(model);
    }
#endif
    bundleName = [[NSBundle mainBundle] bundleIdentifier];
    
    
    struct PKG_HEADER header;
    header.cmd = CMDCPInit;
    header.currentPackage = 1;
    header.totalPackage = 1;
    header.sequId = 0;
    
    NSMutableData *infoData = [NSMutableData dataWithBytes:&header length:sizeof(PKG_HEADER)];
    [infoData appendBytes:&OSType length:sizeof(OSType)];
    [infoData appendData:[self getDataWithPkgString:OSVersion]];
    [infoData appendData:[self getDataWithPkgString:deviceType]];
    [infoData appendData:[self getDataWithPkgString:deviceName]];
    [infoData appendData:[self getDataWithPkgString:bundleName]];
    
    return infoData;
}

+ (NSData *)getDataWithPkgString:(NSString *)string {
    if (string.length > 90) {
        NSData *bodyData = [@"消息过长，暂不支持" dataUsingEncoding:NSUTF8StringEncoding];
        
        Byte len = bodyData.length;
        NSMutableData *pkgData = [NSMutableData dataWithBytes:&len length:sizeof(len)];
        [pkgData appendData:bodyData];
        return pkgData;
    } else {
        NSData *bodyData = [string dataUsingEncoding:NSUTF8StringEncoding];
        
        Byte len = bodyData.length;
        NSMutableData *pkgData = [NSMutableData dataWithBytes:&len length:sizeof(len)];
        [pkgData appendData:bodyData];
        return pkgData;
    }
}

+ (NSData *)getLogDataWithNumber:(UInt32)number date:(NSDate *)date level:(Byte)level content:(NSString *)content {
    struct PKG_HEADER header;
    header.cmd = CMDResLogging;
    header.currentPackage = 1;
    header.totalPackage = 1;
    header.sequId = 0;

    NSTimeInterval timeInterval = [date timeIntervalSinceReferenceDate];
    NSMutableData *logData = [NSMutableData dataWithBytes:&header length:sizeof(PKG_HEADER)];
    [logData appendBytes:&number length:sizeof(number)];
    [logData appendBytes:&timeInterval length:sizeof(NSTimeInterval)];
    [logData appendBytes:&level length:sizeof(Byte)];
    [logData appendData:[self getDataWithPkgString:content]];
    
    return logData;
}

+ (NSData *)getReqLogWithNumber:(UInt32)number {
    struct PKG_HEADER header;
    header.cmd = CMDReqLogging;
    header.currentPackage = 1;
    header.totalPackage = 1;
    header.sequId = 0;
    
    NSMutableData *logData = [NSMutableData dataWithBytes:&header length:sizeof(PKG_HEADER)];
    [logData appendBytes:&number length:sizeof(number)];

    return logData;
}

@end