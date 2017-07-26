//
//  GLOBALS.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/25/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "GLOBALS.h"

@implementation GLOBALS

+ (instancetype)sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        _persons = [NSMutableArray new];
    }
    
    return self;
}

-(NSString *)getCurrentUserId
{
    NSString *userId = @"";
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if([[[userDefaults dictionaryRepresentation] allKeys] containsObject:@"USERID"])
        userId = [userDefaults stringForKey:@"USERID"];
    
    return userId;
}

@end
