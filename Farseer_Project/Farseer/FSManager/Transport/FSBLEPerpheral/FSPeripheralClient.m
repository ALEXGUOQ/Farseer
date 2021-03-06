//
//  FSPeripheralClient.m
//  SLBTServiceDemo
//
//  Created by Go Salo on 2/15/15.
//  Copyright (c) 2015 Go Salo. All rights reserved.
//

#import "FSPeripheralClient.h"
#import "FSBLEPeripheralService.h"
#import "FSLogManager+Peripheral.h"
#import "FSBLEUtilities.h"
#import "FSBLELog.h"
#import "FSDebugCentral.h"
#import "FSFileManager.h"

@interface FSPeripheralClient ()

@property (nonatomic, readonly)CBMutableCharacteristic *infoCharacteristic;
@property (nonatomic, readonly)CBMutableCharacteristic *logCharacteristic;
@property (nonatomic, readonly)CBMutableCharacteristic *dataCharacteristic;
@property (nonatomic, readonly)CBMutableCharacteristic *cmdCharacteristic;

@end

@implementation FSPeripheralClient {
    UInt32                      _waitingLogNumber;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _waitingLogNumber = -1;
    }
    return self;
}

- (void)setPeripheralInfoCharacteristic:(CBMutableCharacteristic *)infoCharacteristic
                      logCharacteristic:(CBMutableCharacteristic *)logCharacteristic
                     dataCharacteristic:(CBMutableCharacteristic *)dataCharacteristic
                      cmdCharacteristic:(CBMutableCharacteristic *)cmdCharacteristic {
    _infoCharacteristic = infoCharacteristic;
    _logCharacteristic = logCharacteristic;
    _dataCharacteristic = dataCharacteristic;
    _cmdCharacteristic = cmdCharacteristic;
    _waitingLogNumber = -1;
}

#pragma mark - Business Logic

- (void)recvSyncLogWithLogNumber:(UInt32)logNum {
    NSArray *logList = [[FSDebugCentral getInstance].logManager logList];
    if (logList.count > logNum) {
        FSBLELog *log = logList[logNum];
        
        [FSBLEPeripheralService updateCharacteristic:_logCharacteristic withData:log.dataValue cmd:CMDResLogging];
        
        if (_waitingLogNumber != -1) {
            _waitingLogNumber = -1;
        }
    } else {
        _waitingLogNumber = logNum;
    }
}

- (void)writeLogToCharacteristicIfWaitingWithLog:(FSBLELog *)log {
    if (_waitingLogNumber == log.log_number) {
        [FSBLEPeripheralService updateCharacteristic:_logCharacteristic withData:log.dataValue cmd:CMDResLogging];
    }
}

- (void)recvGetSendBoxInfoWithPath:(NSString *)path {
    NSData *JSONData = [[FSDebugCentral getInstance].fileManager getDirectoryContentsWithPath:path];
    [FSBLEPeripheralService updateCharacteristic:_cmdCharacteristic withData:JSONData cmd:CMDResSandBoxInfo];
}

- (void)recvGetFileWithPath:(NSString *)path {
    NSData *fileData = [[FSDebugCentral getInstance].fileManager getFileWithPath:path];
    [FSBLEPeripheralService updateCharacteristic:_dataCharacteristic withData:fileData cmd:CMDResData];
}

@end
