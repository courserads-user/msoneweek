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
#import <linkedin-sdk/LISDK.h>

const NSString *GET_USER_INFO_URL = @"https://graph.microsoft.com/v1.0/users/%@@microsoft.com?$select=id,businessPhones,displayName,givenName,jobTitle,mail,mobilePhone,officeLocation,preferredLanguage,surname,userPrincipalName";
const NSString *GET_USER_GROUPS_URL = @"https://graph.microsoft.com/v1.0/users/%@@microsoft.com/memberOf?$select=id,description,displayName,mail,classification,visibility,groupTypes&$top=999";
const NSString *GET_USER_GROUP_MEMBERS_URL = @"https://graph.microsoft.com/v1.0/groups/%@/members?$top=3&$select=id,displayName,mail";
const NSString *GET_USER_GROUP_CONVERSATIONS_URL = @"https://graph.microsoft.com/v1.0/groups/%@/conversations?$top=3";
const NSString *GET_USER_PHOTO_URL = @"https://graph.microsoft.com/v1.0/users/%@@microsoft.com/photo/$value";

const NSString *fontToUse = @"Helvetica-Bold";
const float layerOpacity = .8f;

@interface ARSceneViewController () <ARSCNViewDelegate, ARSessionDelegate>

@property (weak, nonatomic) IBOutlet ARSCNView *sceneView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *messagePanel;
@property (nonatomic) NSMutableArray *currentNodes;
@property (nonatomic) UserInfoModel *currentUserInfoModel;
@property (nonatomic) CGColorRef layerColor;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property CGPoint screenCenter;
@property (weak, nonatomic) IBOutlet UISwitch *sampleSwitch;

@end

@implementation ARSceneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _layerColor = [UIColor whiteColor].CGColor;
    _currentNodes = [NSMutableArray new];
    [self setupScene];
    
    [[self navigationController] setNavigationBarHidden:YES];
    [[self messageLabel] setText:@""];
    self.messagePanel.layer.cornerRadius = 3.0;
    self.messagePanel.clipsToBounds = YES;
	self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
	self.messageLabel.numberOfLines = 0;
	self.messagePanel.hidden = YES;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(insertCubeFrom:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.sceneView addGestureRecognizer:tapGestureRecognizer];
    
	[self.view layoutSubviews];
    
//    [LISDKSessionManager createSessionWithAuth:[NSArray arrayWithObjects:LISDK_BASIC_PROFILE_PERMISSION, nil]
//                                         state:nil
//                        showGoToAppStoreDialog:NO
//                                  successBlock:^(NSString *success) {
//                                      NSLog(@"%s","success called!");
//                                      LISDKSession *session = [[LISDKSessionManager sharedInstance] session];
//                                  } errorBlock:^(NSError *error) {
//                                       NSLog(@"%s","error called!");
//                                  }];
}

- (IBAction)sampleSwitchClicked:(id)sender {
    NSLog(@"Switching");
}

-(void)setupScene
{
    self.sceneView.delegate = self;
    self.sceneView.session.delegate = self;
    self.sceneView.showsStatistics = NO;
    self.sceneView.antialiasingMode = SCNAntialiasingModeMultisampling4X;
    self.sceneView.automaticallyUpdatesLighting = false;
    self.sceneView.preferredFramesPerSecond = 60;
    self.sceneView.contentScaleFactor = 1.3;
    
    if(self.sceneView.scene.lightingEnvironment.contents == nil)
    {
        UIImage *environmentMap = [UIImage imageNamed:@"Models.scnassets/environment_blur.exr"];
        if(environmentMap)
        {
            self.sceneView.scene.lightingEnvironment.contents = environmentMap;
        }
    }
    
    self.sceneView.scene.lightingEnvironment.intensity = 25.0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setScreenCenter:CGPointMake(CGRectGetMidX(self.sceneView.bounds), CGRectGetMidY(self.sceneView.bounds))];
    });
    
    SCNCamera *camera = self.sceneView.pointOfView.camera;
    camera.wantsHDR = YES;
    camera.wantsExposureAdaptation = YES;
    camera.exposureOffset = -1;
    camera.minimumExposure = -1;
    
    ARWorldTrackingSessionConfiguration *configuration = [ARWorldTrackingSessionConfiguration new];
    [configuration setPlaneDetection:ARPlaneDetectionHorizontal];
    [configuration setLightEstimationEnabled:YES];
    
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

-(void)clearNodes
{
	if(_currentNodes.count > 0)
	{
		for (SCNNode *scnnode in _currentNodes) {
			[scnnode removeFromParentNode];
		}
		
		[_currentNodes removeAllObjects];
		
		return;
	}
}

-(void)createGroupNode:(int)groupNumber
{
    UserGroupModel *groupModel = [[_currentUserInfoModel userGroups] objectAtIndex:groupNumber];

    NSString *section1 = [NSString stringWithFormat:@"%@ (%@)\n%@\n\n", [groupModel displayName], [groupModel visibility], [[groupModel mail] stringByReplacingOccurrencesOfString:@"@" withString:@"_at_"]];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:section1 attributes:@{NSFontAttributeName: [UIFont fontWithName:fontToUse size:8],
                                                                                                                    NSForegroundColorAttributeName: [UIColor blackColor]
                                                                                                                    }];

    NSString *membersHeader = @"Members:\n\n";
    [attrString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:membersHeader attributes:@{NSFontAttributeName: [UIFont fontWithName:fontToUse size:10],
                                                                                                                  NSForegroundColorAttributeName: [UIColor redColor],
                                                                                                                  NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}]];

    for (UserGroupMember *member in [groupModel members]) {
        NSString *memberInfo = [NSString stringWithFormat:@"%@\n%@\n\n",[member displayName], [[member mail] stringByReplacingOccurrencesOfString:@"@" withString:@"_at_"]];
        [attrString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:memberInfo attributes:@{NSFontAttributeName: [UIFont fontWithName:fontToUse size:8],
                                                                                                                    NSForegroundColorAttributeName: [UIColor blueColor]}]];
    }

    NSString *convsHeader = @"Conversations:\n\n";
    [attrString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:convsHeader attributes:@{NSFontAttributeName: [UIFont fontWithName:fontToUse size:10],
                                                                                                                  NSForegroundColorAttributeName: [UIColor redColor],
                                                                                                                  NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}]];

    for (UserGroupConversation *conv in [groupModel conversations]) {
        if(conv.senders.count > 0)
        {
            NSString *convInfo = [NSString stringWithFormat:@"%@\n%@\n%@\n\n",[conv topic], [conv lastDeliveredDateTime], [[conv senders] objectAtIndex:0]];
            [attrString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:convInfo attributes:@{NSFontAttributeName: [UIFont fontWithName:fontToUse size:8],
                                                                                                                         NSForegroundColorAttributeName: [UIColor blueColor]}]];
        }
        else
        {
            NSString *convInfo = [NSString stringWithFormat:@"%@\n%@\n\n",[conv topic], [conv lastDeliveredDateTime]];
            [attrString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:convInfo attributes:@{NSFontAttributeName: [UIFont fontWithName:fontToUse size:8],
                                                                                                                       NSForegroundColorAttributeName: [UIColor blueColor]}]];
        }
    }

    CGSize textSize= [attrString size];
	CALayer *layer = [CALayer new];
	[layer setFrame:CGRectMake(10, 0, textSize.width, textSize.height)];
	[layer setBackgroundColor:_layerColor];
    [layer setOpacity:layerOpacity];
	
	CATextLayer *textLayer = [CATextLayer new];
	[textLayer setFrame:[layer bounds]];
	
	[textLayer setString:attrString];
	[textLayer setAlignmentMode:kCAAlignmentLeft];
	[textLayer display];
	[layer addSublayer:textLayer];
	
	SCNBox *box = [SCNBox boxWithWidth:8 height:14 length:0.005 chamferRadius:0.0];
	[[[box firstMaterial] diffuse] setContents:layer];
	SCNNode *node = [SCNNode nodeWithGeometry:box];
	[node setName:[NSString stringWithFormat:@"GROUPNODE%d", groupNumber]];
	
    [node setPosition:SCNVector3Make(-0.5, -2, -15.0)];
	[[[[self sceneView] scene] rootNode] addChildNode:node];
	
	[_currentNodes addObject:node];
}

-(void)addObjectForUser:(UserInfoModel *)model
{
    NSString *section1 = [NSString stringWithFormat:@"%@\n%@\n%@\n\n", [model displayName], [model jobTitle], [[model mail] stringByReplacingOccurrencesOfString:@"@" withString:@"_at_"]];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:section1 attributes:@{NSFontAttributeName: [UIFont fontWithName:fontToUse size:8],
                                                                                                                                      NSForegroundColorAttributeName: [UIColor blackColor]
                                                                                                                                      }];

    NSString *groupHeader = @"Groups:\n\n";
    [attrString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:groupHeader attributes:@{NSFontAttributeName: [UIFont fontWithName:fontToUse size:10],
                                                                                                                     NSForegroundColorAttributeName: [UIColor redColor],
                                                                                                                     NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}]];

    for (UserGroupModel *group in [model userGroups]) {
        NSString *groupInfo = [NSString stringWithFormat:@"%@ (%@)\n%@\n\n",[group displayName], [group visibility], [[group mail] stringByReplacingOccurrencesOfString:@"@" withString:@"_at_"]];
        [attrString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:groupInfo attributes:@{NSFontAttributeName: [UIFont fontWithName:fontToUse size:8],
                                                                                                                      NSForegroundColorAttributeName: [UIColor blueColor]}]];
    }
    
	CGSize textSize = [attrString size];
	CALayer *layer = [CALayer new];
	[layer setFrame:CGRectMake(10, 0, textSize.width, textSize.height)];
	[layer setBackgroundColor:_layerColor];
    [layer setOpacity:layerOpacity];
	
	CATextLayer *textLayer = [CATextLayer new];
	[textLayer setFrame:[layer bounds]];
	
    [textLayer setString:attrString];
    [textLayer setAlignmentMode:kCAAlignmentLeft];
    [textLayer display];
    [layer addSublayer:textLayer];
    
    SCNBox *box = [SCNBox boxWithWidth:8 height:12 length:0.005 chamferRadius:0.0];
    [[[box firstMaterial] diffuse] setContents:layer];
    SCNNode *node = [SCNNode nodeWithGeometry:box];
	[node setName:@"USERINFONODE"];
	
    [node setPosition:SCNVector3Make(-0.5, -2, -15.0)];
    [[[[self sceneView] scene] rootNode] addChildNode:node];
    
    [_currentNodes addObject:node];
}

-(SCNVector3)getSCNVector:(CGPoint)point
{
    CGPoint ppc = [[self sceneView] convertPoint:point fromView:[self sceneView]];
    
    SCNVector3 scenePoint = SCNVector3Make(ppc.x, ppc.y, -12);
    return scenePoint;
}

- (void)insertCubeFrom: (UITapGestureRecognizer *)recognizer {
    if(_currentNodes.count == 1)
	{
		SCNNode *node = [_currentNodes objectAtIndex:0];
		[self clearNodes];
        if([[node name] isEqualToString:@"USERINFONODE"] && [[_currentUserInfoModel userGroups] count] > 0)
		{
			[self createGroupNode:0];
			return;
		}
        else if([[node name] isEqualToString:@"GROUPNODE0"] && [[_currentUserInfoModel userGroups] count] > 1)
        {
            [self createGroupNode:1];
            return;
        }
        else if([[node name] isEqualToString:@"GROUPNODE1"] && [[_currentUserInfoModel userGroups] count] > 2)
        {
            [self createGroupNode:2];
            return;
        }
        else if([[node name] isEqualToString:@"GROUPNODE2"])
        {
            return;
        }
    }
    
    [self clearNodes];
	_currentUserInfoModel = nil;
    UIImage *image = nil;
    if([[self sampleSwitch] isOn])
        image = [UIImage imageNamed:@"arjun.jpg"];
    else
        image = [self imageFromSampleBuffer:self.sceneView.session.currentFrame.capturedImage];

    self.messagePanel.hidden = NO;
    [self.view layoutSubviews];
    [[self messageLabel] setText:@"Identifying Person..."];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        MPOFaceServiceClient *faceClient = [[MPOFaceServiceClient alloc] initWithEndpointAndSubscriptionKey:ProjectOxfordFaceEndpoint key:ProjectOxfordFaceSubscriptionKey];
        NSData *data = UIImageJPEGRepresentation(image, 0.8);
        [faceClient detectWithData:data returnFaceId:YES returnFaceLandmarks:YES returnFaceAttributes:@[] completionBlock:^(NSArray<MPOFace *> *collection, NSError *error) {
            if(!collection || !collection.count)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self messageLabel] setText:@"Unable to Identify user, may be get closer and try again."];
                });
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    self.messagePanel.hidden = YES;
                    [self.view layoutSubviews];
                });
            }
            
            NSMutableArray *faceIds = [NSMutableArray new];
            for (MPOFace *face in collection)
                [faceIds addObject:face.faceId];
            
            [faceClient identifyWithPersonGroupId:@"705d8839-3850-45ad-b85a-bddebfd90199" faceIds:faceIds maxNumberOfCandidates:1 completionBlock:^(NSArray<MPOIdentifyResult *> *collection, NSError *error) {
                NSString *alias = @"";
                if(!collection || !collection.count)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[self messageLabel] setText:@"Unable to Identify user, may be get closer and try again."];
                    });
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        self.messagePanel.hidden = YES;
                        [self.view layoutSubviews];
                    });
                }
                
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
                    
                    if(alias && ![alias isEqualToString:@""])
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[self messageLabel] setText:[NSString stringWithFormat:@"Getting User Info for %@", alias]];
                        });
                        
                        [self processAlias:alias andCompletionHandler:^(id model) {
                            UserInfoModel *userInfo = model;
							_currentUserInfoModel = userInfo;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self ProcessUIForUserInfo:userInfo];
                            });
                        }];
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[self messageLabel] setText:@"Unable to Identify user, may be get closer and try again."];
                        });
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            self.messagePanel.hidden = YES;
                            [self.view layoutSubviews];
                        });
                    }
                }
            }];
        }];
    });
}

- (void)insertCubeForuser:(UserInfoModel *)userInfoModel {
    [self addObjectForUser:userInfoModel];
}

-(void)ProcessUIForUserInfo:(UserInfoModel *)userInfoModel
{
    [[self messageLabel] setText:[NSString stringWithFormat:@"Data Loaded for %@", [userInfoModel displayName]]];
    self.messagePanel.hidden = YES;
    [self.view layoutSubviews];
    [self insertCubeForuser:userInfoModel];
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
                        
                        if([eligibleGroups count] == 3)
                            break;
                    }
                    
                    userInfoModel.userGroups = eligibleGroups;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[self messageLabel] setText:[NSString stringWithFormat:@"Getting photo for %@", alias]];
                    });
                    
                    [self runGraphRequest:[NSString stringWithFormat:GET_USER_PHOTO_URL, alias] andClass:[NSData class] andIsSync:YES andAccessToken:accessToken andRequestCompletionHandler:^(id model) {
                        userInfoModel.photo = model;
                        
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
                    }];
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
        
        if([class isEqual:[NSData class]])
        {
            requestCompletionHandler(data);
        }
        else
        {
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
             
             if([class isEqual:[NSData class]])
             {
                 requestCompletionHandler(data);
             }
             else
             {
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
