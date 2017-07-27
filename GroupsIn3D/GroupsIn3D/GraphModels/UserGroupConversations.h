//
//  UserGroupConversations.h
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/26/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface UserGroupConversations : MTLModel <MTLJSONSerializing>

@property (nonatomic) NSArray *value;

@end
