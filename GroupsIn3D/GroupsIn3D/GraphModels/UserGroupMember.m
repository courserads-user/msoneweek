//
//  UserGroupMember.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/26/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "UserGroupMember.h"

@implementation UserGroupMember

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"id" : @"id",
             @"displayName" : @"displayName",
             @"mail" : @"mail"
             };
}

@end
