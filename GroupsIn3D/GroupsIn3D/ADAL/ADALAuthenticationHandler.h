//
//  ADALAuthenticationHandler.h
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/24/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADALAuthenticationHandler : NSObject

+ (void)getTokenForUser:(NSString *)user andCompletionBlock:(void (^)(NSString*))completionBlock;

@end
