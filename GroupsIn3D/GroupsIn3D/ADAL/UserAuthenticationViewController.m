//
//  UserAuthenticationViewController.m
//  GroupsIn3D
//
//  Created by Prashant Bhide on 7/24/17.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "UserAuthenticationViewController.h"
#import "ADALAuthenticationHandler.h"
#import "ViewController.h"
#import "ARSceneViewController.h"
#import <ProjectOxfordFace/ProjectOxfordFace-umbrella.h>
#import "Constants.h"
#import "GLOBALS.h"

@interface UserAuthenticationViewController ()

@property (weak, nonatomic) IBOutlet UITextField *txtEmailAddress;
@property (weak, nonatomic) IBOutlet UIButton *btnNext;
@property (weak, nonatomic) IBOutlet UIView *spinnerView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation UserAuthenticationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[_spinnerView setHidden:YES];
    if([[[userDefaults dictionaryRepresentation] allKeys] containsObject:@"USERID"])
    {
        NSString *userId = [userDefaults stringForKey:@"USERID"];
        if(![userId isEqualToString:@""])
        {
            [[self txtEmailAddress] setText:userId];
            [self authenticateForUser:userId];
        }
    }
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnNextClicked:(id)sender {
    [self authenticateForUser:[[self txtEmailAddress] text]];
}

-(void)authenticateForUser:(NSString *)userId
{
	[_spinnerView setHidden:NO];
	[_spinner startAnimating];
    [[self btnNext] setEnabled:NO];
    [ADALAuthenticationHandler getTokenForUser:userId andCompletionBlock:^(NSString *accessToken) {
		[_spinner stopAnimating];
        if([accessToken hasPrefix:@"ERROR:"])
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:@"Authentication Error!!!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okaction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil ];
            [alert addAction:okaction];
            
            [self presentViewController:alert animated:YES completion:nil];
            [[self btnNext] setEnabled:YES];
			[_spinner stopAnimating];
			[_spinnerView setHidden:YES];
        }
        else
        {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:userId forKey:@"USERID"];
            [userDefaults synchronize];
            
            MPOFaceServiceClient *faceClient = [[MPOFaceServiceClient alloc] initWithEndpointAndSubscriptionKey:ProjectOxfordFaceEndpoint key:ProjectOxfordFaceSubscriptionKey];
            [faceClient listPersonsWithPersonGroupId:@"705d8839-3850-45ad-b85a-bddebfd90199" completionBlock:^(NSArray<MPOPerson *> *collection, NSError *error) {
                for (MPOPerson *person in collection) {
                    [[[GLOBALS sharedInstance] persons] addObject:person];
                }
            }];
            
            UIStoryboard * sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//            ViewController *mainVC = [sb instantiateViewControllerWithIdentifier:@"arscenevc"]; // arscenevc facedetectvc
//            [self.navigationController pushViewController:mainVC animated:YES];
            
            ARSceneViewController *mainVC = [sb instantiateViewControllerWithIdentifier:@"newarscene"]; // arscenevc facedetectvc
            [self.navigationController pushViewController:mainVC animated:YES];
        }
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
