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

@interface UserAuthenticationViewController ()

@property (weak, nonatomic) IBOutlet UITextField *txtEmailAddress;

@end

@implementation UserAuthenticationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnNextClicked:(id)sender {
    [ADALAuthenticationHandler getTokenForUser:[[self txtEmailAddress] text] andCompletionBlock:^(NSString *accessToken) {
        if([accessToken hasPrefix:@"ERROR:"])
        {
            NSLog(@"ERROR");
        }
        else
        {
            ViewController *mainVC = [[ViewController alloc] init];
            [self presentViewController:mainVC animated:YES completion:NULL];
        }
//        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://outlook.office365.com/api/v2.0/me"]];
//        NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", accessToken];
//        [request addValue:authHeader forHTTPHeaderField:@"Authorization"];
//
//        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
//
//        [NSURLConnection sendAsynchronousRequest:request
//                                           queue:queue
//                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
//         {
//             // Process Response Here
//         }];
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
