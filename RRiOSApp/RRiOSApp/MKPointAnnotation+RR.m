//
//  MKPointAnnotation+RR.m
//  RRiOSApp
//
//  Created by Harlan Kellaway on 10/30/14.
//  Copyright (c) 2014 ___REFUGERESTROOMS___. All rights reserved.
//

#import <objc/runtime.h>
#import "MKPointAnnotation+RR.h"
#import "Restroom.h"

#pragma message "Why are you using a category on MKPointAnnotation? Using the associated object is also kind of hacky."

@implementation MKPointAnnotation (RR)

//@dynamic restroom;

static void *RestroomPropertyKey = &RestroomPropertyKey;

- (Restroom *)restroom
{
    return objc_getAssociatedObject(self, RestroomPropertyKey);
}

- (void)setRestroom:(Restroom *)restroom
{
    objc_setAssociatedObject(self, RestroomPropertyKey, restroom, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
