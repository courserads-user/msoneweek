//
//  GLOBALS.h
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/25/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ProjectOxfordFace/ProjectOxfordFace-umbrella.h>

@interface GLOBALS : NSObject

@property (nonatomic, retain) NSMutableArray<MPOPerson *> *persons;
+ (instancetype)sharedInstance;
-(instancetype)init;
-(NSString *)getCurrentUserId;

@end
