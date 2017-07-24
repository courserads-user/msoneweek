//
//  ADALAuthenticationHandler.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/24/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "ADALAuthenticationHandler.h"
#import "ADAL/ADAuthenticationContext.h"
#import "ADAL/ADAuthenticationResult.h"
#import "ADAL/ADAuthenticationError.h"

@implementation ADALAuthenticationHandler

+ (void)getTokenForUser:(NSString *)user andCompletionBlock:(void (^)(NSString*))completionBlock
{
    ADAuthenticationError *error = nil;
    ADAuthenticationContext *authContext = [ADAuthenticationContext authenticationContextWithAuthority:@"https://login.microsoftonline.com/common"
                                                                        error:&error];
    
    [authContext acquireTokenWithResource:@"https://outlook.office365.com/"
                                 clientId:@"d3590ed6-52b3-4102-aeff-aad2292ab01c"
                              redirectUri:[NSURL URLWithString:@"urn:ietf:wg:oauth:2.0:oob"] // Comes from App Portal
                                   userId:user
                          completionBlock:^(ADAuthenticationResult *result)
     {
         if (AD_SUCCEEDED != result.status){
             completionBlock([NSString stringWithFormat:@"ERROR:%@", result.error.errorDetails]);
         }
         else{
             completionBlock(result.accessToken);
         }
     }];
}

@end
