//
//  UserGroupModel.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/26/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "UserGroupModel.h"

@implementation UserGroupModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"id" : @"id",
             @"groupTypes" : @"groupTypes",
             @"classification" : @"classification",
             @"gdescription" : @"description",
             @"displayName" : @"displayName",
             @"mail" : @"mail",
             @"visibility" : @"visibility"
             };
}

@end
