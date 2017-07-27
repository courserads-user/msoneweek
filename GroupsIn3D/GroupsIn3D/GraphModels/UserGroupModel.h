//
//  UserGroupModel.h
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/26/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface UserGroupModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *id;
@property (nonatomic, copy, readonly) NSArray *groupTypes;
@property (nonatomic, copy, readonly) NSString *classification;
@property (nonatomic, copy, readonly) NSString *gdescription;
@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSString *mail;
@property (nonatomic, copy, readonly) NSString *visibility;
@property (nonatomic) NSArray *members;
@property (nonatomic) NSArray *conversations;

@end
