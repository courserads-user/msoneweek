//
//  UserInfoModel.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/26/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "UserInfoModel.h"

@implementation UserInfoModel

//+(NSValueTransformer *) businessPhonesJSONTransformer {
//    return [MTLJSONAdapter arrayTransformerWithModelClass:[NSString class]];
//}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"id" : @"id",
             @"businessPhones" : @"businessPhones",
             @"displayName" : @"displayName",
             @"givenName" : @"givenName",
             @"jobTitle" : @"jobTitle",
             @"mail" : @"mail",
             @"mobilePhone" : @"mobilePhone",
             @"officeLocation" : @"officeLocation",
             @"preferredLanguage" : @"preferredLanguage",
             @"surname" : @"surname",
             @"userPrincipalName" : @"userPrincipalName"
             };
}

@end
