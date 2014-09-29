//
//  RestroomManager.h
//  RRiOSApp
//
//  Created by Harlan Kellaway on 9/29/14.
//  Copyright (c) 2014 ___REFUGERESTROOMS___. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RestroomManagerDelegate.h"
#import "RestroomCommunicator.h"

#import "RestroomCommunicator.h"

extern NSString *RestroomManagerError;

enum
{
    RestroomManagerErrorSearchCode
};

@interface RestroomManager : NSObject

@property (weak, nonatomic) id <RestroomManagerDelegate> delegate;
@property (strong) RestroomCommunicator *communicator;

- (void)fetchRestroomsForQuery:(NSString *)query;
- (void)searchingForRestroomFailedWithError:(NSError *)error;

@end