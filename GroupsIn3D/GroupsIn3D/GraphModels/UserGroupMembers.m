//
//  UserGroupMembers.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/26/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "UserGroupMembers.h"
#import "UserGroupMember.h"

@implementation UserGroupMembers

+ (NSValueTransformer *)valueJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[UserGroupMember class]];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"value" : @"value"
             };
}

@end
