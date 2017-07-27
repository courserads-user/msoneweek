//
//  UserGroupConversation.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/26/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "UserGroupConversation.h"

@implementation UserGroupConversation

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"id" : @"id",
             @"topic" : @"topic",
             @"preview" : @"preview",
             @"senders" : @"senders",
             @"lastDeliveredDateTime" : @"lastDeliveredDateTime"
             };
}

@end
