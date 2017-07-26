//
//  ViewController.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/24/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "ViewController.h"
#import "VNFaceObservation+Hack.h"
#import <Vision/Vision.h>
#import <ProjectOxfordFace/ProjectOxfordFace-umbrella.h>
#import "Constants.h"
#import "GLOBALS.h"
#import "UIImage+Crop.h"
#import "ADALAuthenticationHandler.h"

@interface ViewController () <ARSCNViewDelegate, ARSessionDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;

@end

    
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sceneView.delegate = self;
    self.sceneView.showsStatistics = YES;
    self.sceneView.session.delegate = self;
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
    // Release any cached data, images, etc that aren't in use.
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
                    
                    [self processAlias:alias];
                }
            }];
        }];
    });
}

-(void)processAlias:(NSString *)alias
{
    NSString *userId = [[GLOBALS sharedInstance] getCurrentUserId];
    [ADALAuthenticationHandler getTokenForUser:userId andCompletionBlock:^(NSString *accessToken) {
        if(![accessToken hasPrefix:@"ERROR:"])
        {
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.microsoft.com/v1.0/users/%@@microsoft.com/", alias]]];
            NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];
            [request addValue:authHeader forHTTPHeaderField:@"Authorization"];
            
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:queue
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
             {
                 NSError *jsonError;
                 id jsonDictionaryOrArray = [NSJSONSerialization JSONObjectWithData:data options:nil error:&jsonError];
                 if(jsonError)
                     NSLog(@"json error : %@", [jsonError localizedDescription]);
                 else
                     NSLog(@"%lu", [jsonDictionaryOrArray count]);
             }];
            
            NSMutableURLRequest *request1 = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.microsoft.com/v1.0/users/%@@microsoft.com/memberOf?$select=id,description,displayName,mail,classification,visibility,groupTypes", alias]]];
            NSString *authHeader1 = [NSString stringWithFormat:@"Bearer %@", accessToken];
            [request1 addValue:authHeader1 forHTTPHeaderField:@"Authorization"];
            
            NSOperationQueue *queue1 = [[NSOperationQueue alloc] init];
            
            [NSURLConnection sendAsynchronousRequest:request1
                                               queue:queue1
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
             {
                 NSError *jsonError;
                 id jsonDictionaryOrArray = [NSJSONSerialization JSONObjectWithData:data options:nil error:&jsonError];
                 if(jsonError)
                     NSLog(@"json error : %@", [jsonError localizedDescription]);
                 else
                     NSLog(@"%lu", [jsonDictionaryOrArray count]);
             }];
        }
    }];
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
