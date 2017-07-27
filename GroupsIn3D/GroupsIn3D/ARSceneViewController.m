//
//  ARSceneViewController.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/26/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "ARSceneViewController.h"
#import "VNFaceObservation+Hack.h"
#import <Vision/Vision.h>
#import <ProjectOxfordFace/ProjectOxfordFace-umbrella.h>
#import "Constants.h"
#import "GLOBALS.h"
#import "UIImage+Crop.h"
#import "ADALAuthenticationHandler.h"
#import "UserInfoModel.h"
#import "UserGroupsModel.h"
#import "UserGroupModel.h"
#import "UserGroupMembers.h"
#import "UserGroupConversations.h"
#import "UserGroupMember.h"
#import "UserGroupConversation.h"
#import <Mantle/Mantle.h>

const NSString *GET_USER_INFO_URL = @"https://graph.microsoft.com/v1.0/users/%@@microsoft.com?$select=id,businessPhones,displayName,givenName,jobTitle,mail,mobilePhone,officeLocation,preferredLanguage,surname,userPrincipalName";
const NSString *GET_USER_GROUPS_URL = @"https://graph.microsoft.com/v1.0/users/%@@microsoft.com/memberOf?$select=id,description,displayName,mail,classification,visibility,groupTypes&$top=999";
const NSString *GET_USER_GROUP_MEMBERS_URL = @"https://graph.microsoft.com/v1.0/groups/%@/members?$top=5&$select=id,displayName,mail";
const NSString *GET_USER_GROUP_CONVERSATIONS_URL = @"https://graph.microsoft.com/v1.0/groups/%@/conversations?$top=5";

@interface ARSceneViewController () <ARSCNViewDelegate, ARSessionDelegate>

@property (weak, nonatomic) IBOutlet ARSCNView *sceneView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *messagePanel;

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;


@end

@implementation ARSceneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sceneView.delegate = self;
    self.sceneView.showsStatistics = YES;
    self.sceneView.session.delegate = self;
    [[self navigationController] setNavigationBarHidden:YES];
    [[self messageLabel] setText:@""];
    self.messagePanel.layer.cornerRadius = 3.0;
    self.messagePanel.clipsToBounds = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Create a session configuration
    ARWorldTrackingSessionConfiguration *configuration = [ARWorldTrackingSessionConfiguration new];
    [configuration setWorldAlignment:ARWorldAlignmentCamera];
    // Run the view's session
    [self.sceneView.session runWithConfiguration:configuration];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.sceneView.session pause];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIImage *)imageFromSampleBuffer:(CVPixelBufferRef)sampleBuffer
{
    UIImage *returnVal = nil;
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:sampleBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [temporaryContext createCGImage:ciImage
                                                fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(sampleBuffer), CVPixelBufferGetHeight(sampleBuffer))];
    if(cgImage)
    {
        returnVal = [self rotateUIImage:[UIImage imageWithCGImage:cgImage] clockwise:YES];
        CGImageRelease(cgImage);
    }
    
    return returnVal;
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UIImage *image = [self imageFromSampleBuffer:self.sceneView.session.currentFrame.capturedImage];
    image = [UIImage imageNamed:@"arjun.jpg"];
    [[self messageLabel] setText:@"Identifying Person..."];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        MPOFaceServiceClient *faceClient = [[MPOFaceServiceClient alloc] initWithEndpointAndSubscriptionKey:ProjectOxfordFaceEndpoint key:ProjectOxfordFaceSubscriptionKey];
        //        [faceClient listPersonGroupsWithCompletion:^(NSArray<MPOPersonGroup *> *collection, NSError *error) {
        //            NSLog(@"");
        //        }];
        
        NSData *data = UIImageJPEGRepresentation(image, 0.8);
        [faceClient detectWithData:data returnFaceId:YES returnFaceLandmarks:YES returnFaceAttributes:@[] completionBlock:^(NSArray<MPOFace *> *collection, NSError *error) {
            NSMutableArray *faceIds = [NSMutableArray new];
            for (MPOFace *face in collection)
                [faceIds addObject:face.faceId];
            
            [faceClient identifyWithPersonGroupId:@"705d8839-3850-45ad-b85a-bddebfd90199" faceIds:faceIds maxNumberOfCandidates:1 completionBlock:^(NSArray<MPOIdentifyResult *> *collection, NSError *error) {
                NSString *alias = @"";
                for (MPOIdentifyResult *result in collection) {
                    for (MPOCandidate *candidate in result.candidates) {
                        NSString *id = [candidate personId];
                        NSMutableArray<MPOPerson *> * persons = [[GLOBALS sharedInstance] persons];
                        for (MPOPerson *person in persons) {
                            if([id isEqualToString:person.personId])
                            {
                                alias = person.name;
                                break;
                            }
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[self messageLabel] setText:[NSString stringWithFormat:@"Getting User Info for %@", alias]];
                    });
                    
                    [self processAlias:alias andCompletionHandler:^(id model) {
                        UserInfoModel *userInfo = model;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self ProcessUIForUserInfo:userInfo];
                        });
                    }];
                }
            }];
        }];
    });
}

-(void)ProcessUIForUserInfo:(UserInfoModel *)userInfoModel
{
    [[self messageLabel] setText:[NSString stringWithFormat:@"Data Loaded for %@", [userInfoModel displayName]]];
    NSLog(@"USER DISPLAY NAME: %@", [userInfoModel displayName]);
    NSLog(@"USER GROUPS COUNT: %lu", [[userInfoModel userGroups] count]);
    for (UserGroupModel *group in [userInfoModel userGroups]) {
        NSLog(@"================================================================================");
        NSLog(@"USER GROUPS NAME: %@", [group displayName]);
        NSLog(@"USER GROUPS MEMBERS COUNT: %lu", [[group members] count]);
        NSLog(@"USER GROUPS CONVERSATIONS COUNT: %lu", [[group conversations] count]);
        for (UserGroupMember *member in [group members]) {
            NSLog(@"USER GROUP MEMBER NAME: %@", [member displayName]);
        }
        
        for (UserGroupConversation *conversation in [group conversations]) {
            NSLog(@"USER GROUP MEMBER CONVERSATION: %@", [conversation topic]);
        }
        
        NSLog(@"================================================================================\n\n\n");
    }
}

-(void)processAlias:(NSString *)alias andCompletionHandler:(void(^)(id))completionHandler
{
    NSString *userId = [[GLOBALS sharedInstance] getCurrentUserId];
    [ADALAuthenticationHandler getTokenForUser:userId andCompletionBlock:^(NSString *accessToken) {
        if([accessToken hasPrefix:@"ERROR:"])
            completionHandler(nil);
        
        [self runGraphRequest:[NSString stringWithFormat:GET_USER_INFO_URL, alias] andClass:[UserInfoModel class] andIsSync:NO andAccessToken:accessToken andRequestCompletionHandler:^(id model) {
            if(!model)
                completionHandler(nil);
            
            UserInfoModel *userInfoModel = model;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self messageLabel] setText:[NSString stringWithFormat:@"Getting Groups for %@", alias]];
            });
            
            [self runGraphRequest:[NSString stringWithFormat:GET_USER_GROUPS_URL, alias] andClass:[UserGroupsModel class] andIsSync:NO andAccessToken:accessToken andRequestCompletionHandler:^(id model) {
                if(model)
                {
                    UserGroupsModel *userGroupsModel = model;
                    NSMutableArray *eligibleGroups = [NSMutableArray new];
                    for (UserGroupModel *group in userGroupsModel.value) {
                        for (NSString *groupType in group.groupTypes) {
                            if([groupType isEqualToString:@"Unified"])
                            {
                                [eligibleGroups addObject:group];
                                break;
                            }
                        }
                        
                        if([eligibleGroups count] == 5)
                            break;
                    }
                    
                    userInfoModel.userGroups = eligibleGroups;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[self messageLabel] setText:[NSString stringWithFormat:@"Getting Group members and conversations for groups for %@", alias]];
                    });
                    
                    for (UserGroupModel *group in userInfoModel.userGroups) {
                        [self runGraphRequest:[NSString stringWithFormat:GET_USER_GROUP_MEMBERS_URL, [group id]] andClass:[UserGroupMembers class] andIsSync:YES andAccessToken:accessToken andRequestCompletionHandler:^(id model) {
                            if(model)
                            {
                                UserGroupMembers *members = model;
                                group.members = members.value;
                                
                                [self runGraphRequest:[NSString stringWithFormat:GET_USER_GROUP_CONVERSATIONS_URL, [group id]] andClass:[UserGroupConversations class] andIsSync:YES andAccessToken:accessToken andRequestCompletionHandler:^(id model) {
                                    if(model)
                                    {
                                        UserGroupConversations *conversations = model;
                                        group.conversations = conversations.value;
                                    }
                                }];
                            }
                        }];
                    }
                    
                    completionHandler(userInfoModel);
                }
                else
                    completionHandler(userInfoModel);
            }];
        }];
    }];
}

- (void)runGraphRequest:(NSString *)url andClass:(Class)class andIsSync:(BOOL)isSync andAccessToken:(NSString *)accessToken andRequestCompletionHandler:(void(^)(id))requestCompletionHandler
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];
    [request addValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    if(isSync)
    {
        NSError *error;
        NSURLResponse *response;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if(!data)
            requestCompletionHandler(nil);
        
        NSError *jsonError;
        NSDictionary *values = [NSJSONSerialization JSONObjectWithData:data
                                                               options:kNilOptions
                                                                 error:&jsonError];
        if(!jsonError)
        {
            NSError *mantleError;
            id model = [MTLJSONAdapter modelOfClass:class fromJSONDictionary:values error:&mantleError];
            if(mantleError)
                requestCompletionHandler(nil);
            else
                requestCompletionHandler(model);
        }
        else
            requestCompletionHandler(nil);
    }
    else
    {
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:queue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             if(!data)
                 requestCompletionHandler(nil);
             
             NSError *jsonError;
             NSDictionary *values = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:kNilOptions
                                                                      error:&jsonError];
             if(!jsonError)
             {
                 NSError *mantleError;
                 id model = [MTLJSONAdapter modelOfClass:class fromJSONDictionary:values error:&mantleError];
                 if(mantleError)
                     requestCompletionHandler(nil);
                 else
                     requestCompletionHandler(model);
             }
             else
                 requestCompletionHandler(nil);
         }];
    }
}

- (UIImage*)rotateUIImage:(UIImage*)sourceImage clockwise:(BOOL)clockwise
{
    CGSize size = sourceImage.size;
    UIGraphicsBeginImageContext(CGSizeMake(size.height, size.width));
    [[UIImage imageWithCGImage:[sourceImage CGImage] scale:1.0 orientation:clockwise ? UIImageOrientationRight : UIImageOrientationLeft] drawInRect:CGRectMake(0,0,size.height ,size.width)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - ARSCNViewDelegate

/*
 // Override to create and configure nodes for anchors added to the view's session.
 - (SCNNode *)renderer:(id<SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
 SCNNode *node = [SCNNode new];
 
 // Add geometry to the node...
 
 return node;
 }
 */

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

@end
