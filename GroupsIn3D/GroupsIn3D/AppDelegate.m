//
//  AppDelegate.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/24/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "AppDelegate.h"
#import "ARSceneViewController.h"
#import "UserAuthenticationViewController.h"
#import <ProjectOxfordFace/ProjectOxfordFace-umbrella.h>
#import "Constants.h"
#import "GLOBALS.h"
#import <linkedin-sdk/LISDK.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    MPOFaceServiceClient *faceClient = [[MPOFaceServiceClient alloc] initWithEndpointAndSubscriptionKey:ProjectOxfordFaceEndpoint key:ProjectOxfordFaceSubscriptionKey];
    [faceClient listPersonsWithPersonGroupId:@"705d8839-3850-45ad-b85a-bddebfd90199" completionBlock:^(NSArray<MPOPerson *> *collection, NSError *error) {
        for (MPOPerson *person in collection) {
            [[[GLOBALS sharedInstance] persons] addObject:person];
        }
    }];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if([[[userDefaults dictionaryRepresentation] allKeys] containsObject:@"USERID"])
    {
        NSString *userId = [userDefaults stringForKey:@"USERID"];
        if(![userId isEqualToString:@""])
        {
            UIStoryboard * sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            //            ViewController *mainVC = [sb instantiateViewControllerWithIdentifier:@"arscenevc"]; // arscenevc facedetectvc
            //            [self.navigationController pushViewController:mainVC animated:YES];
            
            ARSceneViewController *mainVC = [sb instantiateViewControllerWithIdentifier:@"newarscene"]; // arscenevc facedetectvc
            self.window.rootViewController = mainVC;
            [self.window makeKeyAndVisible];
            return YES;
        }
    }
    
    UIStoryboard * sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    //            ViewController *mainVC = [sb instantiateViewControllerWithIdentifier:@"arscenevc"]; // arscenevc facedetectvc
    //            [self.navigationController pushViewController:mainVC animated:YES];
    
    UserAuthenticationViewController *authVC = [sb instantiateViewControllerWithIdentifier:@"userauth"]; // arscenevc facedetectvc
    self.window.rootViewController = authVC;
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([LISDKCallbackHandler shouldHandleUrl:url]) {
        return [LISDKCallbackHandler application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
    return YES;
}

@end
