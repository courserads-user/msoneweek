//
//  UserGroupConversations.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/26/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "UserGroupConversations.h"
#import "UserGroupConversation.h"

@implementation UserGroupConversations

+ (NSValueTransformer *)valueJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[UserGroupConversation class]];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"value" : @"value"
             };
}

@end
