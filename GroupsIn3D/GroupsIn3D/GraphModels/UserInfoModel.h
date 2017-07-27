//
//  UserInfoModel.h
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/26/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import <Mantle/Mantle.h>
#import "UserGroupsModel.h"

@interface UserInfoModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *id;
@property (nonatomic, copy, readonly) NSArray *businessPhones;
@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSString *givenName;
@property (nonatomic, copy, readonly) NSString *jobTitle;
@property (nonatomic, copy, readonly) NSString *mail;
@property (nonatomic, copy, readonly) NSString *mobilePhone;
@property (nonatomic, copy, readonly) NSString *officeLocation;
@property (nonatomic, copy, readonly) NSString *preferredLanguage;
@property (nonatomic, copy, readonly) NSString *surname;
@property (nonatomic, copy, readonly) NSString *userPrincipalName;

@property (nonatomic) NSArray *userGroups;

@end
