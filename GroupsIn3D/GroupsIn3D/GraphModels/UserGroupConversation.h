//
//  UserGroupConversation.h
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/26/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface UserGroupConversation : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *id;
@property (nonatomic, copy, readonly) NSString *topic;
@property (nonatomic, copy, readonly) NSString *preview;
@property (nonatomic, copy, readonly) NSString *lastDeliveredDateTime;
@property (nonatomic, copy, readonly) NSArray *senders;

@end
