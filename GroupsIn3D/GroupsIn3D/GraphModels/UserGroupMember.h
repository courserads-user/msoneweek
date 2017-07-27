//
//  UserGroupMember.h
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/26/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface UserGroupMember : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *id;
@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSString *mail;

@end
