//
//  UserGroupsModel.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/26/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "UserGroupsModel.h"
#import "UserGroupModel.h"

@implementation UserGroupsModel

+ (NSValueTransformer *)valueJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[UserGroupModel class]];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"value" : @"value"
             };
}

@end
